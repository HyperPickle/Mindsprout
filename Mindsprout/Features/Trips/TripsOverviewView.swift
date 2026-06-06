import SwiftUI
import SwiftData

struct TripsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var viewModel = TripsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                TripsHeader { modalCoordinator.present(.newTrip) }
                    .padding(.top, Spacing.md)

                if viewModel.isEmpty {
                    TripsEmptyState { modalCoordinator.present(.newTrip) }
                } else {
                    if let active = viewModel.active {
                        NavigationLink(value: AdventuresRoute.tripDetail(tripID: active.id)) {
                            ActiveTripCard(summary: active)
                        }
                        .buttonStyle(.plain)
                    }
                    if !viewModel.revisit.isEmpty {
                        SectionDivider(title: "REVISIT", color: .white)
                        ForEach(viewModel.revisit) { summary in
                            NavigationLink(value: AdventuresRoute.tripDetail(tripID: summary.id)) {
                                RevisitTripCard(summary: summary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.bottom, Spacing.xl)
        }
        .background(BackgroundSky())
        .task { viewModel.load(context: context) }
        .onChange(of: modalCoordinator.presented) { _, new in
            if new == nil { viewModel.load(context: context) }
        }
    }
}

private struct TripsHeader: View {
    let onNewTrip: () -> Void

    var body: some View {
        HStack {
            Text("Trips")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColor.ink)

            Spacer()

            Button(action: onNewTrip) {
                Label("New trip", systemImage: "plus")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Capsule().fill(AppColor.sand))
                    .contentShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                .fill(AppColor.cardSurface)
                .shadow(color: AppColor.ink.opacity(0.08), radius: 8, x: 0, y: 3)
        )
    }
}

private struct TripsEmptyState: View {
    let onNewTrip: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.primary)
            Text("No trips yet")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.ink)
            Text("Start your first adventure and begin collecting memories.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.inkSecondary)
                .multilineTextAlignment(.center)
            Button("Plan a trip", action: onNewTrip)
                .buttonStyle(.primary)
                .padding(.top, Spacing.xs)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}
