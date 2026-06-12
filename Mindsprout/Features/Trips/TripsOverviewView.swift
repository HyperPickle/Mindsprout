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
                        SectionDivider(title: "REVISIT", color: AppColor.onBackground)
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
                .foregroundStyle(.white)

            Spacer()

            Button(action: onNewTrip) {
                Label("New trip", systemImage: "plus")
                    .font(AppFont.callout)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .contentShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .glassEffect(in: RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
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
                .foregroundStyle(AppColor.onBackground)
            Text("Start your first adventure and begin collecting memories.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.onBackground)
                .multilineTextAlignment(.center)
            Button(action: onNewTrip) {
                Text("Plan a trip")
                    .font(AppFont.button)
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .glassEffect(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.xs)
            .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}
