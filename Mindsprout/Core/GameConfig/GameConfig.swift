//
//  GameConfig.swift
//  Mindsprout
//
//  THE single source of truth for the economy. No XP/level/evolution/currency
//  magic numbers anywhere in feature code — everything reads from here.
//
//  All values below are TUNABLE PLACEHOLDERS pending balancing (Open Question
//  #1) and final art count (Open Question #2). They are intentionally gentle.
//  `GameConfig` is a value type so tests can construct variants and features
//  receive it via the environment (`\.gameConfig`).
//

import Foundation

struct GameConfig: Sendable {
    // MARK: XP awards

    /// Base XP granted by a single "Feed Sprout" commit.
    var baseXP: Int
    /// Bonus XP when the reflection includes at least one photo.
    var photoBonusXP: Int
    /// Bonus XP when the reflection body is an audio recording.
    var audioBonusXP: Int
    /// Bonus XP per consecutive-day streak step (applied by the engine in P3).
    var streakBonusXP: Int

    // MARK: Currency

    /// Soft currency granted per commit (the "1,500" counter). Sinks: future Shop.
    var currencyPerReflection: Int

    // MARK: Level curve

    /// Cumulative XP required to *reach* each level, index 0 == level 1 (0 XP).
    /// Gently escalating. The leveling engine (P3) interpolates/extends past the
    /// table's end using `levelStepBeyondTable`.
    var levelThresholds: [Int]
    /// XP added per level once past the explicit `levelThresholds` table.
    var levelStepBeyondTable: Int

    // MARK: Evolution

    /// Data-driven evolution stages mapped to art asset sets. Adding a stage is
    /// "drop art + append a row" — no code changes (Resolved decision §2).
    var evolutionStages: [EvolutionStage]

    /// A single evolution stage: the level at which it unlocks and the art key
    /// prefix (`sprout_stage{n}_{state}` — see AGENTS.md naming convention).
    struct EvolutionStage: Sendable, Equatable, Identifiable {
        /// Stage index, 0-based; also the `{n}` in the asset name.
        var index: Int
        /// Level at which the Sprout evolves into this stage.
        var unlockLevel: Int
        /// Asset-catalog name prefix, e.g. `sprout_stage0`. State is appended at
        /// render time (`_idle`, `_sleeping`, …).
        var artPrefix: String

        var id: Int { index }
    }

    /// The default, shipped placeholder economy.
    static let `default` = GameConfig(
        baseXP: 50,
        photoBonusXP: 15,
        audioBonusXP: 20,
        streakBonusXP: 10,
        currencyPerReflection: 25,
        // Level 1 starts at 0 XP; each level a bit more than the last.
        levelThresholds: [0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200],
        levelStepBeyondTable: 900,
        evolutionStages: [
            EvolutionStage(index: 0, unlockLevel: 1, artPrefix: "sprout_stage0"),
            EvolutionStage(index: 1, unlockLevel: 4, artPrefix: "sprout_stage1"),
            EvolutionStage(index: 2, unlockLevel: 8, artPrefix: "sprout_stage2")
        ]
    )
}
