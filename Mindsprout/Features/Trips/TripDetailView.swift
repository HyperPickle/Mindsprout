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
        ZStack {
            HStack {
                Button { if let onBack { onBack() } else { dismiss() } } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                Spacer()
                Button {
                    modalCoordinator.present(.editTrip(tripID: tripID))
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
            }
            
            Text(viewModel.trip?.destination ?? "Trip")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 80)
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

}

private struct DayCard: View {
    let reflection: Reflection
    private let photoWidth: CGFloat = 104
    private var photoHeight: CGFloat { photoWidth * 16 / 9 }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            if let featured = reflection.photoAssetIDs.first {
                TripPhotoThumb(assetID: featured)
                    .frame(width: photoWidth, height: photoHeight)
                    .overlay(alignment: .topTrailing) { photoBadge }
            }
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
                if let text = reflection.text, !text.isEmpty {
                    LabelBox(header: "MOMENT", text: String(text.prefix(200)), lineLimit: 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .cardStyle()
    }

    @ViewBuilder private var photoBadge: some View {
        if reflection.photoAssetIDs.count > 1 {
            Label("\(reflection.photoAssetIDs.count)", systemImage: "photo.on.rectangle")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 4)
                .background(Capsule().fill(.black.opacity(0.45)))
                .padding(Spacing.xs)
        }
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
        ZStack {
            BackgroundSky().ignoresSafeArea()
            
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
        HStack {
            Button { if let onBack { onBack() } else { dismiss() } } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(viewModel.trip?.destination ?? "Trip")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("DAY \(current?.dayIndex ?? 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Balanced spacer
            Color.clear.frame(width: 40, height: 40)
        }
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
            VStack(spacing: Spacing.lg) {
                mainCard
                
                if let audioID = reflection.audioAssetID, let url = audioURL(audioID) {
                    AudioPlayerView(url: url)
                        .padding(.horizontal, Spacing.xs)
                }
                
                if reflection.photoAssetIDs.count > 1 {
                    albumSection
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let featured = reflection.photoAssetIDs.first {
                MediaImage(assetID: featured)
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .onTapGesture { lightboxAsset = featured }
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text("REFLECTION")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(AppColor.primary)
                    
                    Spacer()
                    
                    if let date = reflection.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.inkMuted)
                    }
                }
                
                if let text = reflection.text, !text.isEmpty {
                    Text(text)
                        .font(AppFont.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No words for this day, just memories.")
                        .font(AppFont.body)
                        .italic()
                        .foregroundStyle(AppColor.inkMuted)
                }
            }
            .padding(Spacing.lg)
        }
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .shadow(color: AppColor.ink.opacity(0.12), radius: 15, y: 8)
    }

    private var albumSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionDivider(title: "ALBUM", color: .white)
            
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(reflection.photoAssetIDs, id: \.self) { id in
                    MediaImage(assetID: id)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                        .onTapGesture { lightboxAsset = id }
                }
            }
        }
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
