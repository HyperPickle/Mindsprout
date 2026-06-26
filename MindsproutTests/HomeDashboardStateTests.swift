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

struct HomeHungryStateTests {
    @Test func notHungryBeforeEveningBoundary() {
        #expect(
            HomeTab.hungryDisplayState(hour: 19, reflectedToday: false, baseState: .idle) == .idle
        )
    }

    @Test func hungryAtAndAfterEveningBoundaryWhenNoReflection() {
        #expect(
            HomeTab.hungryDisplayState(hour: 20, reflectedToday: false, baseState: .idle) == .hungry
        )
        #expect(
            HomeTab.hungryDisplayState(hour: 23, reflectedToday: false, baseState: .idle) == .hungry
        )
    }

    @Test func neverHungryOnceReflectedToday() {
        #expect(
            HomeTab.hungryDisplayState(hour: 22, reflectedToday: true, baseState: .idle) == .idle
        )
    }

    @Test func passesThroughBaseStateMappingWhenNotHungry() {
        // Sleeping maps to idle on Home; the decision must defer to that mapping
        // when the hungry condition is not met.
        #expect(
            HomeTab.hungryDisplayState(hour: 10, reflectedToday: false, baseState: .sleeping) == .idle
        )
    }
}
