import Testing
@testable import Mindsprout

struct GameConfigTests {

    private let config = GameConfig.default

    @Test func levelThresholdsAreStrictlyIncreasing() {
        let thresholds = config.levelThresholds
        #expect(thresholds.first == 0, "Level 1 must start at 0 XP")
        for (lower, higher) in zip(thresholds, thresholds.dropFirst()) {
            #expect(higher > lower, "Thresholds must strictly increase")
        }
    }

    @Test func xpAwardsArePositive() {
        #expect(config.baseXP > 0)
        #expect(config.currencyPerReflection > 0)
        #expect(config.levelStepBeyondTable > 0)
        #expect(config.maxLevel == 50)
        #expect(config.milestoneLevelInterval == 5)
    }

    @Test func phaseThreeFlatCurveUsesTwentyXPPerLevel() {
        #expect(config.levelThresholds.count == config.maxLevel)
        #expect(config.levelThresholds.first == 0)
        #expect(config.levelThresholds.last == 980)
        for (levelIndex, threshold) in config.levelThresholds.enumerated() {
            #expect(threshold == levelIndex * 20)
        }
    }

    @Test func evolutionStagesAreOrderedAndStartAtLevelOne() {
        let stages = config.evolutionStages
        #expect(!stages.isEmpty)
        #expect(stages.first?.unlockLevel == 1, "First stage unlocks at level 1")
        #expect(stages.first?.index == 0)

        for (earlier, later) in zip(stages, stages.dropFirst()) {
            #expect(later.index == earlier.index + 1, "Stage indices are contiguous")
            #expect(later.unlockLevel > earlier.unlockLevel, "Unlock levels increase")
        }
    }

    @Test func evolutionArtPrefixesFollowNamingConvention() {
        for stage in config.evolutionStages {
            #expect(stage.artPrefix == "sprout_stage\(stage.index)")
        }
    }

    @Test func configIsInjectableAsAValue() {
        // Features receive config by value; a tuned variant overrides cleanly.
        var tuned = GameConfig.default
        tuned.baseXP = 999
        #expect(tuned.baseXP == 999)
        #expect(GameConfig.default.baseXP != 999, "Default is unaffected by copies")
    }
}
