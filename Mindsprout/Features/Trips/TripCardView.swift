import SwiftUI

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

// Asymmetric 3-photo layout: 1 large left, 2 small top-right, optional view bottom-right.
// Used by both RevisitTripCard and DayCard for visual consistency.
struct TripPhotoLayout: View {
    let strip: [UUID?]
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Color.clear.aspectRatio(1, contentMode: .fit)
                TripPhotoThumb(assetID: strip[safe: 0] ?? nil)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    TripPhotoThumb(assetID: strip[safe: 1] ?? nil)
                    TripPhotoThumb(assetID: strip[safe: 2] ?? nil)
                }
                if let trailing { trailing } else { Spacer(minLength: 0) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
                ZStack {
                    LinearGradient(colors: [AppColor.skyTop, AppColor.skyBottom], startPoint: .top, endPoint: .bottom)
                    MediaImage(assetID: coverAssetID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .shadow(color: AppColor.ink.opacity(0.12), radius: 14, x: 0, y: 8)
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

struct ActiveTripCard: View {
    let summary: TripSummary
    var body: some View {
        TripHeroCard(
            trip: summary.trip,
            coverAssetID: summary.coverAssetID,
            memoryCount: summary.memoryCount,
            badge: "ACTIVE"
        )
    }
}

struct RevisitTripCard: View {
    let summary: TripSummary
    private var trip: Trip { summary.trip }
    private var strip: [UUID?] {
        var ids: [UUID?] = summary.photoStripIDs
        while ids.count < 3 { ids.append(nil) }
        return Array(ids.prefix(3))
    }

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
                Text("\(summary.memoryCount) memories")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.ink)
            }
            TripPhotoLayout(strip: strip, trailing: trip.theme.map { AnyView(themeBox($0)) })
        }
        .cardStyle()
    }

    private func themeBox(_ theme: String) -> some View {
        LabelBox(header: "THEME", text: theme)
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
