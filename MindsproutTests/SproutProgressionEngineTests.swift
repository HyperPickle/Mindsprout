import Testing
@testable import Mindsprout

struct SproutProgressionEngineTests {
    private let engine = SproutProgressionEngine(config: .default)

    @Test func startsAtLevelOneWithNoXP() {
        let sprout = Sprout()
        #expect(sprout.level == 1)
        #expect(sprout.xp == 0)
        #expect(engine.level(forTotalXP: sprout.xp) == 1)
    }

    @Test func tenXPDoesNotLevel() {
        let sprout = Sprout()
        let result = engine.applyFeed(to: sprout)

        #expect(result.xpAwarded == 10)
        #expect(result.currencyAwarded == 10)
        #expect(sprout.xp == 10)
        #expect(sprout.level == 1)
        #expect(!result.didLevelUp)
        #expect(!result.shouldPresentMilestoneReward)
    }

    @Test func twentyXPReachesLevelTwo() {
        let sprout = Sprout()
        _ = engine.applyFeed(to: sprout)
        let result = engine.applyFeed(to: sprout)

        #expect(sprout.xp == 20)
        #expect(sprout.level == 2)
        #expect(result.didLevelUp)
        #expect(!result.shouldPresentMilestoneReward)
    }

    @Test func milestoneTriggersAtLevelFiveOnly() {
        let sprout = Sprout()
        var results: [SproutProgressionResult] = []

        for _ in 0..<8 {
            results.append(engine.applyFeed(to: sprout))
        }

        #expect(sprout.level == 5)
        #expect(results.filter(\.shouldPresentMilestoneReward).count == 1)
        #expect(results.last?.newLevel == 5)
        #expect(results.last?.shouldPresentMilestoneReward == true)
    }

    @Test func levelCapsAtFifty() {
        let sprout = Sprout(xp: 970, level: 49, currentStageIndex: 9)
        let capResult = engine.applyFeed(to: sprout)
        let postCapResult = engine.applyFeed(to: sprout)

        #expect(sprout.level == 50)
        #expect(sprout.xp == 980)
        #expect(capResult.didLevelUp)
        #expect(capResult.shouldPresentMilestoneReward)
        #expect(!postCapResult.didLevelUp)
        #expect(!postCapResult.shouldPresentMilestoneReward)
        #expect(sprout.xp == 980)
    }

    @Test func currencyIncrementsByTenPerFeedEvenAfterCap() {
        let sprout = Sprout(xp: 980, level: 50, currency: 30)
        let result = engine.applyFeed(to: sprout)

        #expect(result.currencyAwarded == 10)
        #expect(sprout.currency == 40)
    }
}
