import Foundation

struct GameConfig: Sendable {
    var baseXP: Int
    var currencyPerReflection: Int

    var maxLevel: Int
    var milestoneLevelInterval: Int
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
        baseXP: 10,
        currencyPerReflection: 10,
        maxLevel: 50,
        milestoneLevelInterval: 5,
        levelThresholds: Array(stride(from: 0, through: 980, by: 20)),
        levelStepBeyondTable: 20,
        evolutionStages: [
            EvolutionStage(index: 0, unlockLevel: 1, artPrefix: "sprout_stage0"),
            EvolutionStage(index: 1, unlockLevel: 5, artPrefix: "sprout_stage1"),
            EvolutionStage(index: 2, unlockLevel: 10, artPrefix: "sprout_stage2"),
            EvolutionStage(index: 3, unlockLevel: 15, artPrefix: "sprout_stage3"),
            EvolutionStage(index: 4, unlockLevel: 20, artPrefix: "sprout_stage4"),
            EvolutionStage(index: 5, unlockLevel: 25, artPrefix: "sprout_stage5"),
            EvolutionStage(index: 6, unlockLevel: 30, artPrefix: "sprout_stage6"),
            EvolutionStage(index: 7, unlockLevel: 35, artPrefix: "sprout_stage7"),
            EvolutionStage(index: 8, unlockLevel: 40, artPrefix: "sprout_stage8"),
            EvolutionStage(index: 9, unlockLevel: 45, artPrefix: "sprout_stage9"),
            EvolutionStage(index: 10, unlockLevel: 50, artPrefix: "sprout_stage10")
        ]
    )
}
