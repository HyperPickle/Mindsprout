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
                        SectionDivider(title: "REVISIT")
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
        .background(SkyBackground())
        .task { viewModel.load(context: context) }
        .onChange(of: modalCoordinator.presented) { _, new in
            if new == nil { viewModel.load(context: context) }
        }
    }
}

private struct TripsHeader: View {
    let onNewTrip: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text("Trips")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                Image(systemName: "airplane")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.ink)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Capsule().fill(AppColor.cardSurface))

            Line()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                .frame(height: 1)
                .foregroundStyle(AppColor.inkMuted.opacity(0.6))

            Button(action: onNewTrip) {
                Label("New trip", systemImage: "plus")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Capsule().fill(AppColor.cardSurface))
            }
        }
        .padding(.top, Spacing.xs)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
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
