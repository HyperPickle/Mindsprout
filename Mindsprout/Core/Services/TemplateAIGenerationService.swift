import Foundation

struct TemplateAIGenerationService: AIGenerationService {
    private static let themes = [
        "Wonder came slowly",
        "Small steps, wide horizons",
        "The quiet between places",
        "Found in the detour",
        "Letting the days lead"
    ]
    private static let moodBank = [
        "Serenity", "Curiosity", "Gratitude", "Awe",
        "Courage", "Nostalgia", "Joy", "Stillness"
    ]
    private static let traits = [
        "Courage", "Openness", "Presence", "Patience", "Wonder", "Resilience"
    ]

    static func fallbackInsight(for context: ReflectionContext) -> GrowthInsight {
        let seed = "\(context.tripType.rawValue)|\(context.highlightPrompt)|\(context.text ?? "")"
        let trait = traits[StableHash.index(seed, modulo: traits.count)]
        return GrowthInsight(
            trait: trait,
            blurb: "This moment leaned into \(trait.lowercased())."
        )
    }

    static func fallbackPostcard(for context: ReflectionContext) -> Postcard {
        let place = context.destination.isEmpty ? "the road" : context.destination
        return Postcard(
            title: "Postcard from \(place)",
            body: "You paused in \(place) and noticed what mattered. Keep going."
        )
    }

    func generateTripTheme(_ request: TripThemeRequest) async -> String {
        let seed = "\(request.tripType.rawValue)|\(request.destination)|\(request.expectations.joined(separator: ","))"
        return Self.themes[StableHash.index(seed, modulo: Self.themes.count)]
    }

    func generateHeadline(recentReflectionTexts: [String]) async -> String {
        let mostRecent = recentReflectionTexts
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return mostRecent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func generateMoodTags(_ context: ReflectionContext) async -> [String] {
        let seed = "\(context.highlightPrompt)|\(context.text ?? "")|\(context.destination)"
        let first = StableHash.index(seed, modulo: Self.moodBank.count)
        let second = (first + 1 + StableHash.index(seed + "#2", modulo: Self.moodBank.count - 1)) % Self.moodBank.count
        return [Self.moodBank[first], Self.moodBank[second]]
    }

    func generateGrowthInsight(_ context: ReflectionContext) async -> GrowthInsight {
        Self.fallbackInsight(for: context)
    }

    func generatePostcard(_ context: ReflectionContext) async -> Postcard {
        Self.fallbackPostcard(for: context)
    }
}
