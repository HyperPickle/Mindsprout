import SwiftUI
import SwiftData

@MainActor
@Observable
final class TripViewModel {
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

// MARK: - Intermediate Trip Detail

struct TripDetailView: View {
    let tripID: UUID
    var onBack: (() -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var viewModel = TripViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if let trip = viewModel.trip {
                        TripHeroCard(
                            trip: trip,
                            coverAssetID: trip.coverAssetID,
                            memoryCount: viewModel.reflections.count,
                            showHeadline: false
                        )
                    }
                    if !viewModel.reflections.isEmpty {
                        SectionDivider(title: "MOMENTS", color: AppColor.onBackground)
                        ForEach(Array(viewModel.reflections.enumerated()), id: \.element.id) { offset, reflection in
                            NavigationLink(value: AdventuresRoute.tripDayDetail(tripID: tripID, initialDayIndex: offset)) {
                                DayCard(reflection: reflection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(BackgroundSky())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.load(tripID: tripID, context: context) }
        .onChange(of: modalCoordinator.presented) { _, newValue in
            guard newValue == nil else { return }
            viewModel.load(tripID: tripID, context: context)
            if viewModel.trip == nil {
                if let onBack { onBack() } else { dismiss() }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { if let onBack { onBack() } else { dismiss() } } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Trips")
                        .font(AppFont.callout)
                }
                .padding(.vertical, Spacing.xs)
                .contentShape(Rectangle())
                .foregroundStyle(.white)
            }
            Spacer()
            Button {
                modalCoordinator.present(.editTrip(tripID: tripID))
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, Spacing.xs)
                    .contentShape(Rectangle())
            }
        }
        .overlay {
            Text(viewModel.trip?.destination ?? "")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .glassEffect(in: RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

}

private struct DayCard: View {
    let reflection: Reflection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Day \(reflection.dayIndex)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text("Open memory →")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColor.primary)
            }
            if let featured = reflection.photoAssetIDs.first {
                TripPhotoThumb(assetID: featured)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topTrailing) {
                        if reflection.photoAssetIDs.count > 1 {
                            Label("\(reflection.photoAssetIDs.count)", systemImage: "photo.on.rectangle")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(.black.opacity(0.4)))
                                .padding(Spacing.sm)
                        }
                    }
            }
            if let text = reflection.text, !text.isEmpty {
                LabelBox(header: "MOMENT", text: String(text.prefix(80)))
            }
        }
        .cardStyle()
    }
}

// MARK: - Day Detail

struct TripDayDetailView: View {
    let tripID: UUID
    var initialDayIndex = 0
    var onBack: (() -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TripViewModel()
    @State private var index = 0
    @State private var lightboxAsset: UUID?
    @State private var didSetInitial = false

    private var current: Reflection? {
        viewModel.reflections.indices.contains(index) ? viewModel.reflections[index] : nil
    }

    var body: some View {
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
        .background(BackgroundSky())
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
        HStack {
            Button { if let onBack { onBack() } else { dismiss() } } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(viewModel.trip?.destination ?? "")
                        .font(AppFont.callout)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
            }
            Spacer()
            Text(viewModel.trip?.destination ?? "")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            Text("Day \(current?.dayIndex ?? 1)")
                .font(AppFont.callout)
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Capsule().fill(.white.opacity(0.2)))
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .glassEffect(in: RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
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
                .foregroundStyle(AppColor.ink)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var lightbox: some View {
        if let lightboxAsset {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                MediaImage(assetID: lightboxAsset, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
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
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                        .shadow(color: AppColor.ink.opacity(0.12), radius: 12, y: 6)
                        .onTapGesture { lightboxAsset = featured }
                }
                reflectionCard
                if let audioID = reflection.audioAssetID, let url = audioURL(audioID) {
                    AudioPlayerView(url: url)
                }
                if !reflection.photoAssetIDs.isEmpty {
                    SectionDivider(title: "ALBUM", color: .white)
                    LazyVGrid(columns: columns, spacing: Spacing.xs) {
                        ForEach(reflection.photoAssetIDs, id: \.self) { id in
                            Color.clear
                                .overlay(MediaImage(assetID: id))
                                .aspectRatio(1, contentMode: .fit)
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
                .foregroundStyle(AppColor.ink)
            if let text = reflection.text, !text.isEmpty {
                Text(text)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
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

struct SectionDivider: View {
    let title: LocalizedStringKey
    var color: Color = AppColor.ink

    var body: some View {
        HStack(spacing: Spacing.sm) {
            line
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
            line
        }
    }

    private var line: some View {
        Rectangle().fill(color.opacity(0.25)).frame(height: 1)
    }
}
