import Testing
@testable import Mindsprout

struct ReflectionTaggingServiceTests {
    private let service = ReflectionTaggingService()

    @Test func insightWordsSelectInsightful() {
        let input = ReflectionTaggingInput(
            text: "I realized how much the small detour changed the day.",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 0,
            promptText: ""
        )

        #expect(service.tag(for: input) == .insightful)
    }

    @Test func questionLanguageSelectsCurious() {
        let input = ReflectionTaggingInput(
            text: "Maybe I wonder why this street felt so familiar?",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 0,
            promptText: ""
        )

        #expect(service.tag(for: input) == .curious)
    }

    @Test func gratitudeLanguageSelectsGrateful() {
        let input = ReflectionTaggingInput(
            text: "I felt lucky and grateful for the shared meal.",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 0,
            promptText: ""
        )

        #expect(service.tag(for: input) == .grateful)
    }

    @Test func photoWithSensoryLanguageSelectsVivid() {
        let input = ReflectionTaggingInput(
            text: "The evening was warm and bright beside the river.",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 2,
            promptText: ""
        )

        #expect(service.tag(for: input) == .vivid)
    }

    @Test func audioWithoutTranscriptCanSelectExpressive() {
        let input = ReflectionTaggingInput(
            text: nil,
            bodyKind: .audio,
            audioDurationSeconds: 42,
            photoCount: 0,
            promptText: ""
        )

        #expect(service.tag(for: input) == .expressive)
    }

    @Test func sameInputAlwaysReturnsSameTag() {
        let input = ReflectionTaggingInput(
            text: "I noticed the quiet lane and wondered what it looked like years ago.",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 1,
            promptText: "A place that stayed with you"
        )

        let first = service.tag(for: input)
        let second = service.tag(for: input)

        #expect(first == second)
    }

    @Test func lowSignalInputFallsBackSafely() {
        let shortInput = ReflectionTaggingInput(
            text: "Walked to dinner.",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 0,
            promptText: ""
        )
        let longerInput = ReflectionTaggingInput(
            text: "I walked across the bridge and wrote a small note before dinner.",
            bodyKind: .text,
            audioDurationSeconds: nil,
            photoCount: 0,
            promptText: ""
        )

        #expect(service.tag(for: shortInput) == .present)
        #expect(service.tag(for: longerInput) == .thoughtful)
    }
}
