import Testing
import Foundation
@testable import Mindsprout

struct ReflectionPromptResolverTests {

    private func pack() -> ContentPack {
        ContentPack(
            prompts: PromptPack(
                highlightPrompts: [
                    "default": [
                        HighlightPrompt(id: "quiet-spot", title: "Found a quiet spot", subtitle: "a bench / a cafe corner...")
                    ],
                    "solo": [
                        HighlightPrompt(id: "solo-free", title: "Felt completely free", subtitle: "no plans...")
                    ]
                ],
                inspirationPrompts: []
            ),
            expectations: ExpectationPack(presets: [:])
        )
    }

    @Test func resolvesKnownDefaultPromptID() {
        let text = ReflectionPromptResolver.displayText(forStoredValue: "quiet-spot", in: pack())
        #expect(text == "Found a quiet spot")
    }

    @Test func resolvesPromptIDFromTripSpecificPool() {
        let text = ReflectionPromptResolver.displayText(forStoredValue: "solo-free", in: pack())
        #expect(text == "Felt completely free")
    }

    @Test func treatsUnmatchedValueAsCustomText() {
        let custom = "Temple bells at dawn"
        let text = ReflectionPromptResolver.displayText(forStoredValue: custom, in: pack())
        #expect(text == custom)
    }

    @Test func emptyStoredValueResolvesToEmpty() {
        let text = ReflectionPromptResolver.displayText(forStoredValue: "   ", in: pack())
        #expect(text == "")
    }
}
