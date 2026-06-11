import Foundation

struct SproutProgressionResult: Sendable, Equatable {
    var xpAwarded: Int
    var currencyAwarded: Int
    var previousXP: Int
    var newXP: Int
    var previousLevel: Int
    var newLevel: Int
    var didLevelUp: Bool
    var shouldPresentMilestoneReward: Bool

    static func noAward(for sprout: Sprout) -> SproutProgressionResult {
        SproutProgressionResult(
            xpAwarded: 0,
            currencyAwarded: 0,
            previousXP: sprout.xp,
            newXP: sprout.xp,
            previousLevel: sprout.level,
            newLevel: sprout.level,
            didLevelUp: false,
            shouldPresentMilestoneReward: false
        )
    }
}

struct SproutProgressionEngine: Sendable {
    var config: GameConfig

    init(config: GameConfig = .default) {
        self.config = config
    }

    func applyFeed(to sprout: Sprout) -> SproutProgressionResult {
        let previousXP = sprout.xp
        let previousLevel = clampedLevel(sprout.level)

        guard previousLevel < config.maxLevel else {
            sprout.level = config.maxLevel
            sprout.currentStageIndex = stageIndex(for: config.maxLevel)
            sprout.currency += config.currencyPerReflection
            sprout.state = .sleeping
            return SproutProgressionResult(
                xpAwarded: config.baseXP,
                currencyAwarded: config.currencyPerReflection,
                previousXP: previousXP,
                newXP: sprout.xp,
                previousLevel: previousLevel,
                newLevel: config.maxLevel,
                didLevelUp: false,
                shouldPresentMilestoneReward: false
            )
        }

        let newXP = min(previousXP + config.baseXP, maxXP)
        let newLevel = level(forTotalXP: newXP)
        let newStageIndex = stageIndex(for: newLevel)
        let didLevelUp = newLevel > previousLevel
        let shouldPresentMilestoneReward = didLevelUp
            && crossedMilestone(from: previousLevel, to: newLevel)

        sprout.xp = newXP
        sprout.level = newLevel
        sprout.currentStageIndex = newStageIndex
        sprout.currency += config.currencyPerReflection
        sprout.state = shouldPresentMilestoneReward ? .readyToEvolve : .sleeping

        return SproutProgressionResult(
            xpAwarded: config.baseXP,
            currencyAwarded: config.currencyPerReflection,
            previousXP: previousXP,
            newXP: newXP,
            previousLevel: previousLevel,
            newLevel: newLevel,
            didLevelUp: didLevelUp,
            shouldPresentMilestoneReward: shouldPresentMilestoneReward
        )
    }

    func level(forTotalXP xp: Int) -> Int {
        let level = config.levelThresholds.lastIndex(where: { xp >= $0 }).map { $0 + 1 } ?? 1
        return min(max(1, level), config.maxLevel)
    }

    func levelProgress(totalXP xp: Int, level: Int) -> (within: Int, span: Int) {
        let currentLevel = clampedLevel(level)
        guard currentLevel < config.maxLevel else { return (0, 0) }
        let current = threshold(for: currentLevel)
        let next = threshold(for: currentLevel + 1)
        return (max(0, xp - current), max(0, next - current))
    }

    func progressWithinLevel(totalXP xp: Int, level: Int) -> Double {
        let currentLevel = clampedLevel(level)
        guard currentLevel < config.maxLevel else { return 1 }
        let currentThreshold = threshold(for: currentLevel)
        let nextThreshold = threshold(for: currentLevel + 1)
        guard nextThreshold > currentThreshold else { return 0 }
        return min(max(Double(xp - currentThreshold) / Double(nextThreshold - currentThreshold), 0), 1)
    }

    func stageIndex(for level: Int) -> Int {
        let currentLevel = clampedLevel(level)
        return config.evolutionStages
            .last(where: { currentLevel >= $0.unlockLevel })?
            .index ?? 0
    }

    private var maxXP: Int {
        threshold(for: config.maxLevel)
    }

    private func crossedMilestone(from previousLevel: Int, to newLevel: Int) -> Bool {
        guard config.milestoneLevelInterval > 0 else { return false }
        guard newLevel > previousLevel else { return false }
        return (previousLevel + 1...newLevel).contains { level in
            level.isMultiple(of: config.milestoneLevelInterval)
        }
    }

    private func threshold(for level: Int) -> Int {
        let index = max(0, level - 1)
        if index < config.levelThresholds.count {
            return config.levelThresholds[index]
        }
        let tableMax = config.levelThresholds.last ?? 0
        let beyondCount = index - max(0, config.levelThresholds.count - 1)
        return tableMax + beyondCount * config.levelStepBeyondTable
    }

    private func clampedLevel(_ level: Int) -> Int {
        min(max(1, level), config.maxLevel)
    }
}
