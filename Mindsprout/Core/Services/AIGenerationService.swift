import Foundation

struct TripThemeRequest: Sendable {
    var tripType: TripType
    var destination: String
    var country: String
    var expectations: [String]
}

struct ReflectionContext: Sendable {
    var tripType: TripType
    var destination: String
    var highlightPrompt: String
    var text: String?
    var hasPhoto: Bool
    var hasAudio: Bool
}

struct GrowthInsight: Sendable, Equatable {
    var trait: String
    var blurb: String
}

struct Postcard: Sendable, Equatable {
    var title: String
    var body: String
}

// The seam for AI-derived content. Default impl is on-device and offline
// (TemplateAIGenerationService); a networked LLM impl can replace it here.
protocol AIGenerationService: Sendable {
    func generateTripTheme(_ request: TripThemeRequest) async -> String
    func generateHeadline(recentReflectionTexts: [String]) async -> String
    func generateMoodTags(_ context: ReflectionContext) async -> [String]
    func generateGrowthInsight(_ context: ReflectionContext) async -> GrowthInsight
    func generatePostcard(_ context: ReflectionContext) async -> Postcard
}
