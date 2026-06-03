import Foundation

struct TemplateAIGenerationService: AIGenerationService {
    private let themes = [
        "Wonder came slowly",
        "Small steps, wide horizons",
        "The quiet between places",
        "Found in the detour",
        "Letting the days lead"
    ]
    private let moodBank = [
        "Serenity", "Curiosity", "Gratitude", "Awe",
        "Courage", "Nostalgia", "Joy", "Stillness"
    ]
    private let traits = [
        "Courage", "Openness", "Presence", "Patience", "Wonder", "Resilience"
    ]

    func generateTripTheme(_ request: TripThemeRequest) async -> String {
        let seed = "\(request.tripType.rawValue)|\(request.destination)|\(request.expectations.joined(separator: ","))"
        return themes[StableHash.index(seed, modulo: themes.count)]
    }

    func generateHeadline(recentReflectionTexts: [String]) async -> String {
        let mostRecent = recentReflectionTexts
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return mostRecent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func generateMoodTags(_ context: ReflectionContext) async -> [String] {
        let seed = "\(context.highlightPrompt)|\(context.text ?? "")|\(context.destination)"
        let first = StableHash.index(seed, modulo: moodBank.count)
        let second = (first + 1 + StableHash.index(seed + "#2", modulo: moodBank.count - 1)) % moodBank.count
        return [moodBank[first], moodBank[second]]
    }

    func generateGrowthInsight(_ context: ReflectionContext) async -> GrowthInsight {
        let seed = "\(context.tripType.rawValue)|\(context.highlightPrompt)|\(context.text ?? "")"
        let trait = traits[StableHash.index(seed, modulo: traits.count)]
        return GrowthInsight(
            trait: trait,
            blurb: "This moment leaned into \(trait.lowercased())."
        )
    }

    func generatePostcard(_ context: ReflectionContext) async -> Postcard {
        let place = context.destination.isEmpty ? "the road" : context.destination
        return Postcard(
            title: "Postcard from \(place)",
            body: "You paused in \(place) and noticed what mattered. Keep going."
        )
    }
}
