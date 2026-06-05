import Foundation

struct LevelUpPresentation: Identifiable, Sendable, Equatable {
    var id = UUID()
    var destination: String
    var previousLevel: Int
    var newLevel: Int
    var insight: GrowthInsight
    var postcard: Postcard
}
