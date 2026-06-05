import Testing
@testable import Mindsprout

struct HomeDashboardStateTests {
    @Test func noTripRoutesToCreateTrip() {
        let state = HomeDashboardState(hasActiveTrip: false)
        #expect(state.ctaAction == .createTrip)
    }

    @Test func activeTripRoutesToReflection() {
        let state = HomeDashboardState(hasActiveTrip: true)
        #expect(state.ctaAction == .startReflection)
    }
}
