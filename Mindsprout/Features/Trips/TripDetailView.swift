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
                    if let featured = featuredReflectionData {
                        SectionDivider(title: "FEATURED REFLECTION")
                        featuredReflectionCard(reflection: featured.reflection, index: featured.index)
                    }
                    if !viewModel.reflections.isEmpty {
                        SectionDivider(title: "MOMENTS")
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
        .background(SkyBackground())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.load(tripID: tripID, context: context) }
    }

    private var header: some View {
        HStack {
            Button { if let onBack { onBack() } else { dismiss() } } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Trips")
                        .font(AppFont.callout)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .foregroundStyle(AppColor.ink)
            }
            Spacer()
            Text(viewModel.trip?.destination ?? "")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
            Spacer()
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColor.primary)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                .fill(AppColor.cardSurface)
                .shadow(color: AppColor.ink.opacity(0.08), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private var featuredReflectionData: (index: Int, reflection: Reflection)? {
        guard !viewModel.reflections.isEmpty else { return nil }
        
        if let headline = viewModel.trip?.headlineMemory, !headline.isEmpty {
            if let idx = viewModel.reflections.firstIndex(where: { $0.text?.contains(headline) == true || headline.contains($0.text ?? "---") }) {
                return (idx, viewModel.reflections[idx])
            }
        }
        
        if let idx = viewModel.reflections.enumerated().max(by: { ($0.element.text?.count ?? 0) < ($1.element.text?.count ?? 0) })?.offset {
            return (idx, viewModel.reflections[idx])
        }
        
        return (0, viewModel.reflections[0])
    }

    private func featuredReflectionCard(reflection: Reflection, index: Int) -> some View {
        NavigationLink(value: AdventuresRoute.tripDayDetail(tripID: tripID, initialDayIndex: index)) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let text = reflection.text, !text.isEmpty {
                    Text(text)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.ink)
                        .lineLimit(1)
                }
                
                HStack(alignment: .bottom) {
                    if !reflection.moodTags.isEmpty {
                        HStack(spacing: Spacing.xs) {
                            ForEach(Array(reflection.moodTags.enumerated()), id: \.offset) { i, tag in
                                ReflectionTagChip(text: tag, accent: i.isMultiple(of: 2))
                            }
                        }
                    }
                    Spacer()
                    Text("Open Memory →")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColor.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

private struct DayCard: View {
    let reflection: Reflection
    private var strip: [UUID?] {
        var ids: [UUID?] = reflection.photoAssetIDs.map { Optional($0) }
        while ids.count < 3 { ids.append(nil) }
        return Array(ids.prefix(3))
    }

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
            TripPhotoLayout(
                strip: strip,
                trailing: reflection.text.flatMap { $0.isEmpty ? nil : $0 }
                    .map { AnyView(LabelBox(header: "MOMENT", text: String($0.prefix(80)))) }
            )
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
        .background(SkyBackground())
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
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(viewModel.trip?.destination ?? "")
                        .font(AppFont.callout)
                        .lineLimit(1)
                }
                .foregroundStyle(AppColor.ink)
            }
            Spacer()
            Text(viewModel.trip?.destination ?? "")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
            Spacer()
            Text("Day \(current?.dayIndex ?? 1)")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Capsule().fill(AppColor.sand))
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                .fill(AppColor.cardSurface)
                .shadow(color: AppColor.ink.opacity(0.08), radius: 8, x: 0, y: 3)
        )
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
            ReflectionTagsSection(
                tags: reflection.moodTags,
                title: "Reflection Tags",
                emptyLabel: "Add tags"
            ) { updatedTags in
                reflection.moodTags = updatedTags
                try? context.save()
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
