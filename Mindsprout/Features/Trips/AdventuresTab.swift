import SwiftUI

enum AdventuresRoute: Hashable {
    case tripDetail(tripID: UUID)
}

struct AdventuresTab: View {
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var path: [AdventuresRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            PlaceholderScreen(
                title: "Adventures",
                systemImage: "airplane.departure",
                note: "Trips overview & detail — Phase 1."
            )
            .navigationTitle("Adventures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        modalCoordinator.present(.newTrip)
                    } label: {
                        Label("New trip", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: AdventuresRoute.self) { route in
                switch route {
                case .tripDetail:
                    PlaceholderScreen(
                        title: "Trip detail",
                        systemImage: "map",
                        note: "Day-by-day reflections — Phase 1."
                    )
                }
            }
        }
    }
}

#Preview {
    AdventuresTab()
        .environment(ModalCoordinator())
}
