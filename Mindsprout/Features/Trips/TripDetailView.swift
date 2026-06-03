import SwiftUI
import SwiftData

@MainActor
@Observable
final class TripDetailViewModel {
    private(set) var trip: Trip?
    private(set) var reflections: [Reflection] = []

    func load(tripID: UUID, context: ModelContext) {
        var descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tripID })
        descriptor.fetchLimit = 1
        trip = try? context.fetch(descriptor).first
        if let trip {
            reflections = (try? TripRepository(context: context).reflections(for: trip)) ?? []
        }
    }
}

struct TripDetailView: View {
    let tripID: UUID
    var initialDayIndex = 0

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TripDetailViewModel()
    @State private var index = 0
    @State private var lightboxAsset: UUID?
    @State private var didSetInitial = false

    private var current: Reflection? {
        viewModel.reflections.indices.contains(index) ? viewModel.reflections[index] : nil
    }

    var body: some View {
        ZStack {
            SkyBackground()
            VStack(spacing: 0) {
                header
                if viewModel.reflections.isEmpty {
                    emptyState
                } else {
                    TabView(selection: $index) {
                        ForEach(Array(viewModel.reflections.enumerated()), id: \.element.id) { offset, reflection in
                            DayContentView(reflection: reflection, lightboxAsset: $lightboxAsset)
                                .tag(offset)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.load(tripID: tripID, context: context)
            if !didSetInitial {
                index = min(initialDayIndex, max(0, viewModel.reflections.count - 1))
                didSetInitial = true
            }
        }
        .overlay { lightbox }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button { dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColor.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.cardSurface))
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("Day \(current?.dayIndex ?? 1)")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                if let place = current?.locationLabel {
                    Text(place)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.inkSecondary)
                }
            }
            Spacer()
            DayTrail()
                .frame(width: 90, height: 36)
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.bottom, Spacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.inkMuted)
            Text("No reflections yet")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.ink)
            Text("Memories from this trip will appear here.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.inkSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var lightbox: some View {
        if let lightboxAsset {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                MediaImage(assetID: lightboxAsset, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                    .padding(Spacing.lg)
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            }
            .transition(.opacity)
            .onTapGesture { self.lightboxAsset = nil }
        }
    }
}

private struct DayContentView: View {
    let reflection: Reflection
    @Binding var lightboxAsset: UUID?
    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if let featured = reflection.photoAssetIDs.first {
                    MediaImage(assetID: featured)
                        .frame(height: 230)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                        .shadow(color: AppColor.ink.opacity(0.12), radius: 12, y: 6)
                        .onTapGesture { lightboxAsset = featured }
                }

                reflectionCard

                if let audioID = reflection.audioAssetID, let url = audioURL(audioID) {
                    AudioPlayerView(url: url)
                }

                if !reflection.photoAssetIDs.isEmpty {
                    SectionDivider(title: "ALBUM")
                    LazyVGrid(columns: columns, spacing: Spacing.xs) {
                        ForEach(reflection.photoAssetIDs, id: \.self) { id in
                            MediaImage(assetID: id)
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                                .onTapGesture { lightboxAsset = id }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("REFLECTION")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(AppColor.inkMuted)
            if let text = reflection.text, !text.isEmpty {
                Text(text)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !reflection.moodTags.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Spacer()
                    ForEach(Array(reflection.moodTags.enumerated()), id: \.offset) { i, tag in
                        MoodPill(text: tag, accent: i.isMultiple(of: 2))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func audioURL(_ id: UUID) -> URL? {
        guard let path = MediaImage.relativePath(for: id, in: context) else { return nil }
        return env.mediaStore.url(for: path)
    }
}

private struct MoodPill: View {
    let text: String
    let accent: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(accent ? AppColor.inkSecondary : AppColor.primaryEdge)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule().fill((accent ? AppColor.currency : AppColor.primary).opacity(0.18))
            )
    }
}

struct SectionDivider: View {
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: Spacing.sm) {
            line
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(AppColor.inkMuted)
            line
        }
        .padding(.vertical, Spacing.xs)
    }

    private var line: some View {
        Rectangle().fill(AppColor.inkMuted.opacity(0.3)).frame(height: 1)
    }
}

private struct DayTrail: View {
    var body: some View {
        ZStack(alignment: .trailing) {
            TrailLine()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 5]))
                .foregroundStyle(AppColor.inkMuted)
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppColor.primary)
        }
    }
}

private struct TrailLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 14, y: rect.midY),
            control1: CGPoint(x: rect.midX - 10, y: rect.maxY),
            control2: CGPoint(x: rect.midX, y: rect.midY)
        )
        return path
    }
}
