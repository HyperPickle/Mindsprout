import SwiftUI

enum AdventuresRoute: Hashable {
    case tripDetail(tripID: UUID)
    case tripDayDetail(tripID: UUID, initialDayIndex: Int)
}

struct AdventuresTab: View {
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var path: [AdventuresRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            TripsOverviewView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AdventuresRoute.self) { route in
                    switch route {
                    case .tripDetail(let tripID):
                        TripDetailView(tripID: tripID)
                    case .tripDayDetail(let tripID, let initialDayIndex):
                        TripDayDetailView(tripID: tripID, initialDayIndex: initialDayIndex)
                    }
                }
        }
    }
}

#Preview {
    AdventuresTab()
        .environment(ModalCoordinator())
}
