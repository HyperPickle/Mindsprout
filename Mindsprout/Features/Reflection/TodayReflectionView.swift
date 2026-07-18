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
    @Environment(ModalCoordinator.self) private var coordinator

    @State private var reflections: [Reflection] = []
    @State private var selectedID: UUID?
    @State private var tripID: UUID?
    @State private var contentPack: ContentPack?
    @State private var lightboxAsset: UUID?

    private var selectedReflection: Reflection? {
        reflections.first { $0.id == selectedID }
    }

    var body: some View {
        ZStack {
            BackgroundSky().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
            // Keep the reader in a readable column on iPad; sky stays full-bleed.
            .contentColumn()
        }
        .presentationDetents([.fraction(0.9)])
        .presentationDragIndicator(.visible)
        .task { load() }
        .overlay {
            ReflectionLightbox(photos: selectedReflection?.photoAssetIDs ?? [], selectedAsset: $lightboxAsset)
                .animation(.easeInOut(duration: 0.2), value: lightboxAsset)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Text("Today's Reflection")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            Button {
                startNewReflection()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 56, height: 56)
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .accessibilityLabel("New reflection")
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if reflections.isEmpty {
            unavailableState
        } else {
            TabView(selection: $selectedID) {
                ForEach(reflections, id: \.id) { reflection in
                    pageBody(reflection)
                        .tag(Optional(reflection.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: reflections.count > 1 ? .always : .never))
        }
    }

    private func pageBody(_ reflection: Reflection) -> some View {
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
        }
    }

    private func startNewReflection() {
        guard let tripID else { return }
        coordinator.present(.reflection(tripID: tripID))
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
                TodayReflectionTextCard(
                    text: text,
                    tag: primaryTag(for: reflection)
                )
            }
        case .audio:
            VStack(alignment: .trailing, spacing: Spacing.md) {
                if let audioID = reflection.audioAssetID {
                    ReflectionAudioPlayer(audioAssetID: audioID)
                        .frame(maxWidth: .infinity)
                }
                if let transcript = reflection.transcript, !transcript.isEmpty {
                    ReflectionTranscriptSection(transcript: transcript)
                }
                if let tag = primaryTag(for: reflection) {
                    ReflectionMoodTagChip(tag: tag)
                }
            }
        }
    }

    private func primaryTag(for reflection: Reflection) -> String? {
        reflection.moodTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
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
        guard let found = try? context.fetch(descriptor).first, !found.isDraft else {
            reflections = []
            return
        }
        tripID = found.tripID

        let tID = found.tripID
        var tripDescriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tID })
        tripDescriptor.fetchLimit = 1
        if let trip = try? context.fetch(tripDescriptor).first {
            reflections = todaysCompletedReflections(for: trip, in: context)
        } else {
            reflections = [found]
        }
        // Open on the passed reflection (the most recent), falling back to the
        // newest available if it's somehow no longer in today's set.
        selectedID = reflections.first { $0.id == reflectionID }?.id ?? reflections.first?.id
    }
}

// MARK: - Text Card

private struct TodayReflectionTextCard: View {
    let text: String
    let tag: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let tag {
                ReflectionMoodTagChip(tag: tag)
            }

            Text(text)
                .font(AppFont.body)
                .lineSpacing(4)
                .foregroundStyle(AppColor.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
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
        highlightPrompt: String = "quiet-spot",
        moodTags: [String] = ["Honest"]
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
        reflection.moodTags = moodTags

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
                .environment(ModalCoordinator())
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
                .environment(ModalCoordinator())
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
                .environment(ModalCoordinator())
        }
}
