import Foundation

enum HomeDashboardCTAAction: Equatable {
    case createTrip
    case startReflection
    case viewTodayReflection(reflectionID: UUID)
}

struct HomeDashboardState: Equatable {
    var hasActiveTrip: Bool
    /// The ID of today's already-completed reflection for the active trip, if one
    /// exists. Drives the switch from `Reflect to Feed` to `Today's Reflection`.
    var completedTodayReflectionID: UUID? = nil

    var ctaAction: HomeDashboardCTAAction {
        guard hasActiveTrip else { return .createTrip }
        if let completedTodayReflectionID {
            return .viewTodayReflection(reflectionID: completedTodayReflectionID)
        }
        return .startReflection
    }
}
