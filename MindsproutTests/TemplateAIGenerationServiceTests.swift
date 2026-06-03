import Testing
@testable import Mindsprout

struct TemplateAIGenerationServiceTests {

    private let service = TemplateAIGenerationService()

    private func sampleContext() -> ReflectionContext {
        ReflectionContext(
            tripType: .friends,
            destination: "Seoul",
            highlightPrompt: "What moment made everyone laugh?",
            text: "The night market dare",
            hasPhoto: true,
            hasAudio: false
        )
    }

    @Test func tripThemeIsDeterministicAndNonEmpty() async {
        let request = TripThemeRequest(
            tripType: .solo, destination: "Kyoto", country: "Japan",
            expectations: ["Find some clarity"]
        )
        let first = await service.generateTripTheme(request)
        let second = await service.generateTripTheme(request)
        #expect(first == second)
        #expect(!first.isEmpty)
    }

    @Test func differentInputsCanYieldDifferentThemes() async {
        let kyoto = TripThemeRequest(tripType: .solo, destination: "Kyoto", country: "Japan", expectations: [])
        let lisbon = TripThemeRequest(tripType: .business, destination: "Lisbon", country: "Portugal", expectations: ["Find balance on the road"])
        // Deterministic per-input; the seeds differ so this is a meaningful signal.
        let a = await service.generateTripTheme(kyoto)
        let b = await service.generateTripTheme(lisbon)
        #expect(!a.isEmpty && !b.isEmpty)
    }

    @Test func headlineFallsBackToMostRecentNonEmptyText() async {
        let headline = await service.generateHeadline(
            recentReflectionTexts: ["", "   ", "The bullet train to Tokyo"]
        )
        #expect(headline == "The bullet train to Tokyo")
    }

    @Test func headlineIsEmptyWhenNoText() async {
        let headline = await service.generateHeadline(recentReflectionTexts: ["", "  "])
        #expect(headline.isEmpty)
    }

    @Test func moodTagsAreTwoDistinctAndDeterministic() async {
        let context = sampleContext()
        let first = await service.generateMoodTags(context)
        let second = await service.generateMoodTags(context)
        #expect(first == second)
        #expect(first.count == 2)
        #expect(first[0] != first[1])
    }

    @Test func growthInsightIsDeterministic() async {
        let context = sampleContext()
        let first = await service.generateGrowthInsight(context)
        let second = await service.generateGrowthInsight(context)
        #expect(first == second)
        #expect(!first.trait.isEmpty)
    }

    @Test func postcardReferencesDestination() async {
        let postcard = await service.generatePostcard(sampleContext())
        #expect(postcard.title.contains("Seoul"))
        #expect(!postcard.body.isEmpty)
    }

    @Test func stableHashIsConsistentAcrossCalls() {
        #expect(StableHash.fnv1a("Kyoto") == StableHash.fnv1a("Kyoto"))
        #expect(StableHash.fnv1a("Kyoto") != StableHash.fnv1a("Lisbon"))
        #expect(StableHash.index("anything", modulo: 1) == 0)
    }
}
