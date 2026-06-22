import Foundation
import SwiftData

@Model
final class Sprout {
    var id: UUID = UUID()
    var name: String = ""
    var xp: Int = 0
    var level: Int = 1
    var currentStageIndex: Int = 0
    var currency: Int = 0
    var state: SproutState = SproutState.idle
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        xp: Int = 0,
        level: Int = 1,
        currentStageIndex: Int = 0,
        currency: Int = 0,
        state: SproutState = .idle,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.xp = xp
        self.level = level
        self.currentStageIndex = currentStageIndex
        self.currency = currency
        self.state = state
        self.createdAt = createdAt
    }
}
