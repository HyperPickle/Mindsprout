import Testing
@testable import Mindsprout

struct SproutStateTests {
    @Test func sleepingMapsToIdleOnHome() {
        #expect(SproutState.sleeping.homeDisplayState == .idle)
    }

    @Test func nonSleepingStatesPassThroughOnHome() {
        for state in SproutState.allCases where state != .sleeping {
            #expect(state.homeDisplayState == state)
        }
    }
}
