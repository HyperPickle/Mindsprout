import SwiftUI
import SwiftData

/// Read-only viewer for today's completed reflection on the active trip,
/// presented from Home as a dismissible bottom sheet. Strictly
/// presentational: no edit or delete affordances. Drafts are never shown — the
/// view only renders a reflection that has been submitted.
struct TodayReflectionView: View {
    let reflectionID: UUID

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var reflection: Reflection?
    @State private var contentPack: ContentPack?
    @State private var lightboxAsset: UUID?
    @State private var innerContentHeight: CGFloat = 0

    private static let headerEstimate: CGFloat = 60
    private static let bottomClearance: CGFloat = 28

    private var modalHeight: CGFloat {
        let total = Self.headerEstimate + innerContentHeight + Self.bottomClearance
        return min(total, UIScreen.main.bounds.height * 0.88)
    }

    var body: some View {
        ZStack {
            BackgroundSky().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
        }
        .presentationDetents(innerContentHeight == 0 ? [.medium] : [.height(modalHeight)])
        .presentationDragIndicator(.visible)
        .task { load() }
        .overlay {
            ReflectionLightbox(photos: reflection?.photoAssetIDs ?? [], selectedAsset: $lightboxAsset)
                .animation(.easeInOut(duration: 0.2), value: lightboxAsset)
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Today's Reflection")
            .font(AppFont.sectionTitle)
            .foregroundStyle(AppColor.label)
            .lineLimit(1)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .readableLiquidGlass(in: Capsule())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.sm)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let reflection {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    dateAndPrompt(reflection)

                    if !reflection.photoAssetIDs.isEmpty {
                        ReflectionPhotoCarousel(photos: reflection.photoAssetIDs) { tapped in
                            lightboxAsset = tapped
                        }
                    }

                    bodySection(reflection)
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ReflectionContentHeightKey.self, value: geo.size.height)
                    }
                )
            }
            .onPreferenceChange(ReflectionContentHeightKey.self) { innerContentHeight = $0 }
        } else {
            unavailableState
        }
    }

    private func dateAndPrompt(_ reflection: Reflection) -> some View {
        Text(promptText(reflection))
            .font(AppFont.screenTitle)
            .foregroundStyle(AppColor.label)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func bodySection(_ reflection: Reflection) -> some View {
        switch reflection.bodyKind {
        case .text:
            if let text = reflection.text, !text.isEmpty {
                Text(text)
                    .font(AppFont.body)
                    .lineSpacing(4)
                    .foregroundStyle(AppColor.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.lg)
                    .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
        case .audio:
            VStack(spacing: Spacing.md) {
                if let audioID = reflection.audioAssetID {
                    ReflectionAudioPlayer(audioAssetID: audioID)
                }
                if let transcript = reflection.transcript, !transcript.isEmpty {
                    ReflectionTranscriptSection(transcript: transcript)
                }
            }
        }
    }

    private var unavailableState: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.label)
            Text("This reflection isn't available.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Data

    private func promptText(_ reflection: Reflection) -> String {
        guard let contentPack else { return reflection.highlightPrompt }
        return ReflectionPromptResolver.displayText(forStoredValue: reflection.highlightPrompt, in: contentPack)
    }

    private func load() {
        contentPack = try? env.contentPackLoader.load()

        var descriptor = FetchDescriptor<Reflection>(predicate: #Predicate { $0.id == reflectionID })
        descriptor.fetchLimit = 1
        // Only a submitted reflection may surface here; drafts must never appear.
        if let found = try? context.fetch(descriptor).first, !found.isDraft {
            reflection = found
        } else {
            reflection = nil
        }
    }
}

// MARK: - Preference Key

private struct ReflectionContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Previews

private enum TodayReflectionPreviewData {
    @MainActor
    static func make(
        bodyKind: ReflectionBodyKind,
        text: String? = nil,
        photoCount: Int = 0,
        hasAudio: Bool = false,
        transcript: String? = nil,
        highlightPrompt: String = "quiet-spot"
    ) -> (ModelContainer, UUID) {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        let reflection = Reflection(
            tripID: UUID(),
            dayIndex: 3,
            date: Date(),
            highlightPrompt: highlightPrompt,
            bodyKind: bodyKind,
            text: text,
            isDraft: false
        )

        var photoIDs: [UUID] = []
        for _ in 0..<photoCount {
            let asset = MediaAsset(kind: .photo, relativePath: "preview/photo-\(UUID().uuidString).jpg")
            context.insert(asset)
            photoIDs.append(asset.id)
        }
        reflection.photoAssetIDs = photoIDs

        if hasAudio {
            let asset = MediaAsset(kind: .audio, relativePath: "preview/audio-\(UUID().uuidString).m4a")
            context.insert(asset)
            reflection.audioAssetID = asset.id
        }
        reflection.transcript = transcript

        context.insert(reflection)
        try? context.save()
        return (container, reflection.id)
    }
}

#Preview("Text · No Photos") {
    let (container, id) = TodayReflectionPreviewData.make(
        bodyKind: .text,
        text: "I slowed down enough to notice the small things — the smell of the rain on warm stone, the way the light fell across the square.",
        highlightPrompt: "quiet-spot"
    )
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            TodayReflectionView(reflectionID: id)
                .modelContainer(container)
                .environment(\.appEnvironment, .preview)
        }
}

#Preview("Text · Multi Photo") {
    let (container, id) = TodayReflectionPreviewData.make(
        bodyKind: .text,
        text: "Three photos that say everything about today.",
        photoCount: 3,
        highlightPrompt: "Temple bells at dawn"
    )
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            TodayReflectionView(reflectionID: id)
                .modelContainer(container)
                .environment(\.appEnvironment, .preview)
        }
}

#Preview("Audio · Transcript") {
    let (container, id) = TodayReflectionPreviewData.make(
        bodyKind: .audio,
        photoCount: 1,
        hasAudio: true,
        transcript: "I recorded my thoughts while walking back along the harbour at dusk.",
        highlightPrompt: "sunrise-sunset"
    )
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            TodayReflectionView(reflectionID: id)
                .modelContainer(container)
                .environment(\.appEnvironment, .preview)
        }
}
