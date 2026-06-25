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

enum TripDaySelection {
    static func initialIndex(in reflections: [Reflection], selectedReflectionID: UUID?) -> Int {
        guard
            let selectedReflectionID,
            let selectedIndex = reflections.firstIndex(where: { $0.id == selectedReflectionID })
        else {
            return 0
        }
        return selectedIndex
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
                            coverAssetID: TripHero.coverAssetID(for: trip, reflections: viewModel.reflections),
                            memoryCount: viewModel.reflections.count
                        )
                    }
                    if !viewModel.reflections.isEmpty {
                        SectionDivider(title: "MOMENTS", color: AppColor.label)
                        ForEach(viewModel.reflections, id: \.id) { reflection in
                            NavigationLink(value: TripsRoute.tripDayDetail(tripID: tripID, initialReflectionID: reflection.id)) {
                                DayCard(reflection: reflection)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            }
                            .id(reflection.id)
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
        HStack(spacing: Spacing.xs) {
            Button { if let onBack { onBack() } else { dismiss() } } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 56, height: 56)
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            Text(viewModel.trip?.destination ?? "Trip")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, Spacing.sm)
                .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            Button {
                modalCoordinator.present(.editTrip(tripID: tripID))
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 56, height: 56)
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

}

private struct DayCard: View {
    let reflection: Reflection
    private let photoHeight: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let featured = reflection.photoAssetIDs.first {
                TripPhotoThumb(assetID: featured)
                    .frame(height: photoHeight)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottomTrailing) { photoBadge }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Day \(reflection.dayIndex)")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                    Spacer()
                    Text("Open memory →")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    @ViewBuilder private var photoBadge: some View {
        if reflection.photoAssetIDs.count > 1 {
            Label("\(reflection.photoAssetIDs.count)", systemImage: "photo.on.rectangle")
                .font(AppFont.eyebrow)
                .foregroundStyle(AppColor.label)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 4)
                .glassEffect(in: Capsule())
                .padding(Spacing.sm)
        }
    }
}

// MARK: - Day Detail

struct TripDayDetailView: View {
    let tripID: UUID
    var initialReflectionID: UUID?
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
                index = TripDaySelection.initialIndex(
                    in: viewModel.reflections,
                    selectedReflectionID: initialReflectionID
                )
                didSetInitial = true
            }
        }
        .overlay {
            ReflectionLightbox(photos: current?.photoAssetIDs ?? [], selectedAsset: $lightboxAsset)
                .animation(.easeInOut(duration: 0.2), value: lightboxAsset)
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Button { if let onBack { onBack() } else { dismiss() } } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 56, height: 56)
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            Text(dayTitle)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .center)
                .padding(.horizontal, Spacing.sm)
                .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            Color.clear
                .frame(width: 56, height: 56)
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private var dayTitle: String {
        guard let current else { return "Day 1" }
        return "Day \(current.dayIndex)"
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.label)
            Text("No reflections yet")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
            Text("Memories from this trip will appear here.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.label)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

}

private struct DayContentView: View {
    let reflection: Reflection
    @Binding var lightboxAsset: UUID?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 3)

    private var primaryTag: String? {
        reflection.moodTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                mainCard

                if let audioID = reflection.audioAssetID {
                    ReflectionAudioPlayer(audioAssetID: audioID)

                    if let transcript = reflection.transcript, !transcript.isEmpty {
                        ReflectionTranscriptSection(transcript: transcript)
                    }
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
                GeometryReader { proxy in
                    MediaImage(assetID: featured, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { lightboxAsset = featured }
                }
                .frame(height: 280)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("REFLECTION")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.label)

                    if let tag = primaryTag {
                        Spacer(minLength: Spacing.sm)
                        ReflectionMoodTagChip(tag: tag)
                    }
                }

                if let text = reflection.text, !text.isEmpty {
                    Text(text)
                        .font(AppFont.body)
                        .lineSpacing(4)
                        .foregroundStyle(AppColor.label)
                        .fixedSize(horizontal: false, vertical: true)
                } else if reflection.bodyKind == .audio {
                    Text("Reflected out loud. Listen below.")
                        .font(AppFont.body)
                        .italic()
                        .foregroundStyle(AppColor.label)
                } else {
                    Text("No words for this day, just memories.")
                        .font(AppFont.body)
                        .italic()
                        .foregroundStyle(AppColor.label)
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var albumSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionDivider(title: "ALBUM", color: AppColor.label)
            
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(reflection.photoAssetIDs, id: \.self) { id in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay { MediaImage(assetID: id) }
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                        .onTapGesture { lightboxAsset = id }
                }
            }
        }
    }
}

struct SectionDivider: View {
    let title: LocalizedStringKey
    var color: Color = AppColor.label

    var body: some View {
        HStack(spacing: Spacing.sm) {
            line
            Text(title)
                .font(AppFont.eyebrow)
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
