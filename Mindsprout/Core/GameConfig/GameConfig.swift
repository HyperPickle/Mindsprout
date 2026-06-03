import Foundation

struct GameConfig: Sendable {
    var baseXP: Int
    var photoBonusXP: Int
    var audioBonusXP: Int
    var streakBonusXP: Int
    var currencyPerReflection: Int

    var levelThresholds: [Int]
    var levelStepBeyondTable: Int

    var evolutionStages: [EvolutionStage]

    struct EvolutionStage: Sendable, Equatable, Identifiable {
        var index: Int
        var unlockLevel: Int
        var artPrefix: String
        var id: Int { index }
    }

    static let `default` = GameConfig(
        baseXP: 50,
        photoBonusXP: 15,
        audioBonusXP: 20,
        streakBonusXP: 10,
        currencyPerReflection: 25,
        levelThresholds: [0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200],
        levelStepBeyondTable: 900,
        evolutionStages: [
            EvolutionStage(index: 0, unlockLevel: 1, artPrefix: "sprout_stage0"),
            EvolutionStage(index: 1, unlockLevel: 4, artPrefix: "sprout_stage1"),
            EvolutionStage(index: 2, unlockLevel: 8, artPrefix: "sprout_stage2")
        ]
    )
}
