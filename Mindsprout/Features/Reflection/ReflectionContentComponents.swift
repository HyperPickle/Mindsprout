import SwiftUI
import SwiftData

// Reusable building blocks for rendering a completed reflection's media and
// body. Shared between the trip-day detail screen and the read-only
// "Today's Reflection" viewer so playback, lightbox, and transcript behaviour
// live in one place.

// MARK: - Prompt resolution

enum ReflectionPromptResolver {
    /// Resolves a reflection's stored `highlightPrompt` for display. Stored
    /// values are either a content-pack prompt ID or free-form custom text; when
    /// the value matches a known prompt ID we show its title, otherwise we treat
    /// the value itself as the custom prompt the traveler wrote.
    static func displayText(forStoredValue value: String, in pack: ContentPack) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let all = pack.prompts.highlightPrompts.values.flatMap { $0 }
        if let match = all.first(where: { $0.id == trimmed }) {
            return match.title
        }
        return value
    }
}

// MARK: - Paged photo carousel

/// A paged hero carousel for a reflection's photos with page indicators. Tapping
/// a photo invokes `onTap`, typically to open `ReflectionLightbox`.
struct ReflectionPhotoCarousel: View {
    let photos: [UUID]
    var height: CGFloat = 300
    let onTap: (UUID) -> Void

    @State private var selection: UUID?

    var body: some View {
        TabView(selection: selectionBinding) {
            ForEach(photos, id: \.self) { id in
                MediaImage(assetID: id, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture { onTap(id) }
                    .tag(id)
            }
        }
        .frame(height: height)
        .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var selectionBinding: Binding<UUID> {
        Binding(
            get: { selection ?? photos.first ?? UUID() },
            set: { selection = $0 }
        )
    }
}

// MARK: - Full-screen lightbox

/// Full-screen, paged lightbox for tapped photos. Renders only while
/// `selectedAsset` is non-nil and `photos` is non-empty.
struct ReflectionLightbox: View {
    let photos: [UUID]
    @Binding var selectedAsset: UUID?

    var body: some View {
        if selectedAsset != nil, !photos.isEmpty {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                    .onTapGesture { selectedAsset = nil }

                TabView(selection: selectionBinding) {
                    ForEach(photos, id: \.self) { id in
                        MediaImage(assetID: id, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .padding(Spacing.lg)
                            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                            .tag(id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))

                VStack {
                    HStack {
                        Spacer()
                        Button { selectedAsset = nil } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.black.opacity(0.4)))
                        }
                    }
                    Spacer()
                }
                .padding(Spacing.screenEdge)
            }
            .transition(.opacity)
        }
    }

    private var selectionBinding: Binding<UUID> {
        Binding(
            get: { selectedAsset ?? photos.first ?? UUID() },
            set: { selectedAsset = $0 }
        )
    }
}

// MARK: - Audio playback

/// Resolves a reflection's audio asset to a file URL and renders the shared
/// `AudioPlayerView`. Nothing is shown if the file can't be resolved.
struct ReflectionAudioPlayer: View {
    let audioAssetID: UUID

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env

    var body: some View {
        if let url {
            AudioPlayerView(url: url)
        }
    }

    private var url: URL? {
        guard let path = MediaImage.relativePath(for: audioAssetID, in: context) else { return nil }
        return env.mediaStore.url(for: path)
    }
}

// MARK: - Transcript

/// Collapsed, expandable transcript section for audio reflections.
struct ReflectionTranscriptSection: View {
    let transcript: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("Transcript")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.label)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.label)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(transcript)
                    .font(AppFont.body)
                    .lineSpacing(4)
                    .foregroundStyle(AppColor.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}
