import Testing
import Foundation
@testable import Mindsprout

struct HomeDashboardStateTests {
    @Test func noTripRoutesToCreateTrip() {
        let state = HomeDashboardState(hasActiveTrip: false)
        #expect(state.ctaAction == .createTrip)
    }

    @Test func noTripIgnoresCompletedReflection() {
        // Defensive: without an active trip the CTA must still be Create Trip
        // even if a stale reflection ID somehow lingers.
        let state = HomeDashboardState(hasActiveTrip: false, completedTodayReflectionID: UUID())
        #expect(state.ctaAction == .createTrip)
    }

    @Test func activeTripWithoutTodaysReflectionRoutesToReflection() {
        let state = HomeDashboardState(hasActiveTrip: true)
        #expect(state.ctaAction == .startReflection)
    }

    @Test func activeTripWithTodaysReflectionRoutesToViewer() {
        let id = UUID()
        let state = HomeDashboardState(hasActiveTrip: true, completedTodayReflectionID: id)
        #expect(state.ctaAction == .viewTodayReflection(reflectionID: id))
    }
}
