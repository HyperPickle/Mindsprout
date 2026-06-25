import SwiftUI

enum TripsRoute: Hashable {
    case tripDetail(tripID: UUID)
    case tripDayDetail(tripID: UUID, initialReflectionID: UUID?)
}

struct TripsTab: View {
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var path: [TripsRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            TripsOverviewView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: TripsRoute.self) { route in
                    switch route {
                    case .tripDetail(let tripID):
                        TripDetailView(tripID: tripID, onBack: { path.removeLast() })
                    case .tripDayDetail(let tripID, let initialReflectionID):
                        TripDayDetailView(tripID: tripID, initialReflectionID: initialReflectionID, onBack: { path.removeLast() })
                    }
                }
        }
    }
}

#Preview {
    TripsTab()
        .environment(ModalCoordinator())
}
