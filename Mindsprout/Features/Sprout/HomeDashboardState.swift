import Foundation

enum HomeDashboardCTAAction: Equatable {
    case startReflection
    case createTrip
}

struct HomeDashboardState: Equatable {
    var hasActiveTrip: Bool

    var ctaAction: HomeDashboardCTAAction {
        hasActiveTrip ? .startReflection : .createTrip
    }
}
