import SwiftUI
import SwiftData

struct TripsOverviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var viewModel = TripsViewModel()

    var body: some View {
        ZStack {
            BackgroundSky()

            ScrollView {
                VStack(spacing: Spacing.md) {
                    TripsHeader { modalCoordinator.present(.newTrip) }
                        .padding(.top, Spacing.md)

                    if viewModel.isEmpty {
                        TripsEmptyState { modalCoordinator.present(.newTrip) }
                    } else {
                        if let active = viewModel.active {
                            NavigationLink(value: TripsRoute.tripDetail(tripID: active.id)) {
                                ActiveTripCard(summary: active)
                            }
                            .buttonStyle(.plain)
                        }
                        if !viewModel.revisit.isEmpty {
                            SectionDivider(title: "REVISIT", color: AppColor.label)
                            ForEach(viewModel.revisit) { summary in
                                NavigationLink(value: TripsRoute.tripDetail(tripID: summary.id)) {
                                    RevisitTripCard(summary: summary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.xl)
                .contentColumn()
            }
        }
        .task { viewModel.load(context: context) }
        .onChange(of: modalCoordinator.presented) { _, new in
            if new == nil { viewModel.load(context: context) }
        }
    }
}

private struct TripsHeader: View {
    let onNewTrip: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            HStack {
                Text("Trips")
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.label)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            Button(action: onNewTrip) {
                Label("New Trip", systemImage: "plus")
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.label)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 56)
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
    }
}

private struct TripsEmptyState: View {
    let onNewTrip: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.label)
            Text("No trips yet")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
            Text("Start your first trip and begin collecting memories.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
            Button(action: onNewTrip) {
                Text("Plan a trip")
                    .font(AppFont.button)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColor.label)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
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
