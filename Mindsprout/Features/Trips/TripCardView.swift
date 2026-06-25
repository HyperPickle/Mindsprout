import SwiftUI
import MapKit
import UIKit

// Reusable photo thumbnail with gradient fallback.
struct TripPhotoThumb: View {
    let assetID: UUID?
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [AppColor.skyTop, .white], startPoint: .top, endPoint: .bottom)
                MediaImage(assetID: assetID, contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// Photo hero card — shared by TripDetailView hero content.
struct TripHeroCard: View {
    let trip: Trip
    let coverAssetID: UUID?
    let memoryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroBackground
                .frame(height: 196)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: CornerRadius.medium,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: CornerRadius.medium,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    Text(TripDateFormat.range(trip.startDate, trip.endDate, includeYear: false))
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                    Spacer()
                    Text("\(memoryCount) \(memoryCount == 1 ? "memory" : "memories")")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                }

                if let headline = trip.headlineMemory, !headline.isEmpty {
                    Rectangle().fill(AppColor.label.opacity(0.08)).frame(height: 1)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("MEMORY")
                            .font(AppFont.eyebrow)
                            .tracking(0.5)
                            .foregroundStyle(AppColor.label)
                        Text(headline)
                            .font(AppFont.bodyEmphasized)
                            .foregroundStyle(AppColor.label)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
        }
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var heroBackground: some View {
        TripMapHero(trip: trip, coverAssetID: coverAssetID)
    }
}

// Map/photo hero — shared by TripHeroCard (detail) and TripOverviewCard (overview).
struct TripMapHero: View {
    let trip: Trip
    let coverAssetID: UUID?

    var body: some View {
        if coverAssetID != nil {
            // Photos take priority as the hero image.
            TripMapFallback(assetID: coverAssetID)
        } else if let lat = trip.latitude, let lng = trip.longitude {
            // Fall back to a map snapshot when no photo is available.
            TripMapSnapshot(
                tripID: trip.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                fallbackAssetID: nil
            )
        } else {
            // Gradient placeholder when there is neither a photo nor a location.
            TripMapFallback(assetID: nil)
        }
    }
}

private struct TripMapSnapshot: View {
    let tripID: UUID
    let coordinate: CLLocationCoordinate2D
    let fallbackAssetID: UUID?

    @Environment(\.appEnvironment) private var env
    @Environment(\.displayScale) private var displayScale
    @State private var snapshot: UIImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            content
                .frame(width: proxy.size.width, height: proxy.size.height)
                .task(id: snapshotKey(for: proxy.size)) {
                    await loadSnapshotIfNeeded(for: proxy.size)
                }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot {
            Image(uiImage: snapshot)
                .resizable()
                .scaledToFill()
        } else {
            TripMapLiveFallback(
                coordinate: coordinate,
                assetID: fallbackAssetID
            )
        }
    }

    private func snapshotKey(for size: CGSize) -> String {
        snapshotRelativePath(for: size)
    }

    @MainActor
    private func loadSnapshotIfNeeded(for size: CGSize) async {
        guard size.width > 1, size.height > 1 else { return }

        loadTask?.cancel()
        let relativePath = snapshotRelativePath(for: size)

        let task = Task {
            if let cached = loadCachedSnapshot(relativePath: relativePath) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    snapshot = cached
                }
                return
            }

            let options = MKMapSnapshotter.Options()
            options.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
            options.size = size
            options.scale = displayScale
            options.mapType = .standard

            do {
                let result = try await MKMapSnapshotter(options: options).start()
                guard !Task.isCancelled else { return }
                persistSnapshotImage(result.image, relativePath: relativePath)
                await MainActor.run {
                    snapshot = result.image
                }
            } catch {
                guard !Task.isCancelled else { return }
            }
        }

        loadTask = task
        await task.value
    }

    private func snapshotRelativePath(for size: CGSize) -> String {
        let pixelWidth = Int((size.width * displayScale).rounded())
        let pixelHeight = Int((size.height * displayScale).rounded())
        let latBucket = Int((coordinate.latitude * 10_000).rounded())
        let lngBucket = Int((coordinate.longitude * 10_000).rounded())
        return "maps/trips/\(tripID.uuidString)_\(latBucket)_\(lngBucket)_\(pixelWidth)x\(pixelHeight).jpg"
    }

    private func loadCachedSnapshot(relativePath: String) -> UIImage? {
        UIImage(contentsOfFile: env.mediaStore.url(for: relativePath).path)
    }

    private func persistSnapshotImage(_ image: UIImage, relativePath: String) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? env.mediaStore.write(data, relativePath: relativePath)
    }
}

private struct TripMapLiveFallback: View {
    let coordinate: CLLocationCoordinate2D
    let assetID: UUID?

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColor.skyTop, AppColor.skyBottom], startPoint: .top, endPoint: .bottom)

            if let assetID {
                MediaImage(assetID: assetID)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(0.22)
            }

            Map(initialPosition: .region(region))
                .mapStyle(.standard)
                .disabled(true)
                .allowsHitTesting(false)
        }
    }
}

private struct TripMapFallback: View {
    let assetID: UUID?

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColor.skyTop, AppColor.skyBottom], startPoint: .top, endPoint: .bottom)
            MediaImage(assetID: assetID, showsShimmerPlaceholder: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Unified overview card: text header on top, map hero below.
struct TripOverviewCard: View {
    let summary: TripSummary
    private var trip: Trip { summary.trip }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.label)
                    Text(TripDateFormat.range(trip.startDate, trip.endDate, includeYear: true))
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                }
                Spacer()
                Text("\(summary.memoryCount) \(summary.memoryCount == 1 ? "memory" : "memories")")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.label)
            }
            TripMapHero(trip: trip, coverAssetID: summary.coverAssetID)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .padding(Spacing.md)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

struct ActiveTripCard: View {
    let summary: TripSummary
    var body: some View {
        TripOverviewCard(summary: summary)
    }
}

struct RevisitTripCard: View {
    let summary: TripSummary
    var body: some View {
        TripOverviewCard(summary: summary)
    }
}

// Small label+body box used as the trailing slot in TripPhotoLayout.
struct LabelBox: View {
    let header: String
    let text: String
    var lineLimit: Int = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(header)
                .font(AppFont.eyebrow)
                .tracking(0.5)
                .foregroundStyle(AppColor.label)
            Text(text)
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(AppColor.label)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}
