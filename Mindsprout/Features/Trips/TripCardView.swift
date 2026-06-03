import SwiftUI

struct ActiveTripCard: View {
    let summary: TripSummary

    private var trip: Trip { summary.trip }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                MediaImage(assetID: summary.coverAssetID)
                    .frame(height: 196)
                    .frame(maxWidth: .infinity)
                    .clipped()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center, endPoint: .bottom
                )
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                overlay
            }
            .overlay(alignment: .topTrailing) {
                Text("ACTIVE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black.opacity(0.28)))
                    .padding(Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("HEADLINE MEMORY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(AppColor.inkMuted)
                Text(trip.headlineMemory ?? "")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
        }
        .background(AppColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .shadow(color: AppColor.ink.opacity(0.12), radius: 14, x: 0, y: 8)
    }

    private var overlay: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(trip.destination)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Text(trip.country)
                        .font(AppFont.callout)
                        .opacity(0.9)
                }
                Text(TripDateFormat.range(trip.startDate, trip.endDate, includeYear: false))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .opacity(0.85)
            }
            Spacer()
            Text("\(summary.memoryCount) memories")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .opacity(0.95)
        }
        .foregroundStyle(.white)
        .padding(Spacing.md)
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
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(trip.destination)
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.ink)
                        Text(trip.country)
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.inkMuted)
                    }
                    Text(TripDateFormat.range(trip.startDate, trip.endDate, includeYear: true))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.inkMuted)
                }
                Spacer()
                Text("\(summary.memoryCount) memories")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.currency)
            }

            photoStrip

            if let theme = trip.theme {
                VStack(alignment: .leading, spacing: 1) {
                    Text("THEME")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(AppColor.inkMuted)
                    Text(theme)
                        .font(AppFont.bodyEmphasized)
                        .foregroundStyle(AppColor.ink)
                }
            }
        }
        .cardStyle()
    }

    private var photoStrip: some View {
        HStack(spacing: Spacing.xs) {
            thumb(strip[0])
                .frame(maxWidth: .infinity)
            VStack(spacing: Spacing.xs) {
                thumb(strip[1])
                thumb(strip[2])
            }
            .frame(width: 96)
        }
        .frame(height: 132)
    }

    private func thumb(_ id: UUID?) -> some View {
        MediaImage(assetID: id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}
