import SwiftUI
import SwiftData

struct ReflectTab: View {
    @Binding var selection: AppTab
    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator

    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]

    private var activeTrip: Trip? {
        TripResolver.active(in: trips)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if let trip = activeTrip {
                    ReflectionFlow(tripID: trip.id) {
                        selection = .home
                    } onMilestoneReward: { presentation in
                        modalCoordinator.present(.levelUp(presentation))
                    }
                } else {
                    BackgroundSky()
                    emptyState
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Forces NavigationStack content to clear the FloatingTabBar circle
                Color.clear.frame(height: 100)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "airplane.circle")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("No active trip")
                .font(AppFont.headline)
                .foregroundStyle(.white)
            Text("Start a trip on the Adventures tab to begin reflecting.")
                .font(AppFont.callout)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Spacer()
        }
    }
}

#Preview {
    // Create an in-memory ModelContainer for SwiftData previews
    let schema = Schema([Trip.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    // Optionally insert mock data here if needed
    // let context = container.mainContext

    return ReflectTab(selection: .constant(.reflect))
        .environment(\.modelContext, container.mainContext)
}
