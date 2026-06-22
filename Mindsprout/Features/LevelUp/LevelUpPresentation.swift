import Foundation

struct LevelUpPresentation: Identifiable, Sendable, Equatable {
    var id = UUID()
    var destination: String
    var previousLevel: Int
    var newLevel: Int
    var insight: GrowthInsight
    var postcard: Postcard
}

extension LevelUpPresentation {
    static func fallback(
        destination: String,
        previousLevel: Int,
        newLevel: Int,
        context: ReflectionContext
    ) -> LevelUpPresentation {
        LevelUpPresentation(
            destination: destination,
            previousLevel: previousLevel,
            newLevel: newLevel,
            insight: TemplateAIGenerationService.fallbackInsight(for: context),
            postcard: TemplateAIGenerationService.fallbackPostcard(for: context)
        )
    }
}
