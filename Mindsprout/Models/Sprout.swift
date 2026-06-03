//
//  Sprout.swift
//  Mindsprout
//
//  The single global companion. XP and currency accrue across all trips.
//  Skeletal Phase 0 stub: holds state only — the leveling engine that reads
//  `GameConfig` to apply XP, compute levels, and detect evolution thresholds
//  arrives in Phase 3.
//

import Foundation
import SwiftData

@Model
final class Sprout {
    var id: UUID = UUID()

    /// Total accumulated experience across all reflections.
    var xp: Int = 0
    /// Current level, derived from `xp` via `GameConfig` (cached here).
    var level: Int = 1
    /// Index into `GameConfig`'s evolution stage table → art asset set.
    var currentStageIndex: Int = 0
    /// Soft currency (the "1,500" counter); spending deferred to the Shop.
    var currency: Int = 0

    var state: SproutState = SproutState.sleeping

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        xp: Int = 0,
        level: Int = 1,
        currentStageIndex: Int = 0,
        currency: Int = 0,
        state: SproutState = .sleeping,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.xp = xp
        self.level = level
        self.currentStageIndex = currentStageIndex
        self.currency = currency
        self.state = state
        self.createdAt = createdAt
    }
}
