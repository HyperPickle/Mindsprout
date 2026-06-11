import SwiftUI
import MapKit

// Reusable photo thumbnail with gradient fallback.
struct TripPhotoThumb: View {
    let assetID: UUID?
    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColor.skyTop, AppColor.sand], startPoint: .top, endPoint: .bottom)
            MediaImage(assetID: assetID)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// Photo hero card — shared by ActiveTripCard (overview) and TripDetailView (hero section).
// badge: optional capsule label ("ACTIVE", "MOST INSIGHT: Serenity", etc.)
// showHeadline: false when the headline is displayed separately below the card.
struct TripHeroCard: View {
    let trip: Trip
    let coverAssetID: UUID?
    let memoryCount: Int
    var badge: String? = nil
    var showHeadline: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                heroBackground
                    .frame(height: 196)
                    .frame(maxWidth: .infinity)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                photoOverlay
            }
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.black.opacity(0.28)))
                        .padding(Spacing.sm)
                }
            }
            if showHeadline, let headline = trip.headlineMemory, !headline.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("HEADLINE MEMORY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(AppColor.ink)
                    Text(headline)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
            }
        }
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .shadow(color: AppColor.ink.opacity(0.12), radius: 14, x: 0, y: 8)
    }

    private var heroBackground: some View {
        TripMapHero(trip: trip, coverAssetID: coverAssetID)
    }

    private var photoOverlay: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.destination)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(TripDateFormat.range(trip.startDate, trip.endDate, includeYear: false))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .opacity(0.85)
            }
            Spacer()
            Text("\(memoryCount) memories")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .opacity(0.95)
        }
        .foregroundStyle(.white)
        .padding(Spacing.md)
    }
}

// Map/photo hero — shared by TripHeroCard (detail) and TripOverviewCard (overview).
struct TripMapHero: View {
    let trip: Trip
    let coverAssetID: UUID?

    @ViewBuilder
    var body: some View {
        if let lat = trip.latitude, let lng = trip.longitude {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
            Map(initialPosition: .region(region))
                .mapStyle(.standard)
                .disabled(true)
                .allowsHitTesting(false)
        } else {
            ZStack {
                LinearGradient(colors: [AppColor.skyTop, AppColor.skyBottom], startPoint: .top, endPoint: .bottom)
                MediaImage(assetID: coverAssetID)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// Unified overview card: text header on top, map hero below, cream card surface.
struct TripOverviewCard: View {
    let summary: TripSummary
    var badge: String? = nil
    private var trip: Trip { summary.trip }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.ink)
                    Text(TripDateFormat.range(trip.startDate, trip.endDate, includeYear: true))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    if let badge {
                        Text(badge)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppColor.primary))
                    }
                    Text("\(summary.memoryCount) memories")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.ink)
                }
            }
            TripMapHero(trip: trip, coverAssetID: summary.coverAssetID)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .cardStyle()
    }
}

struct ActiveTripCard: View {
    let summary: TripSummary
    var body: some View {
        TripOverviewCard(summary: summary, badge: "ACTIVE")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(header)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(AppColor.ink)
            Text(text)
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(AppColor.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.sand)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}
