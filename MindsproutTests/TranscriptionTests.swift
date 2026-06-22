import Testing
import Foundation
import SwiftData
@testable import Mindsprout

private struct FakeTranscriber: Transcribing {
    let result: String
    func transcribe(url: URL) async throws -> String { result }
}

private struct FailingTranscriber: Transcribing {
    let error: Error
    func transcribe(url: URL) async throws -> String { throw error }
}

private struct FakeLocalizedTranscriptionError: LocalizedError {
    var errorDescription: String? { "Transcription failed in tests." }
}

@MainActor
struct TranscriptionTests {

    private func makeContentPack() -> ContentPack {
        ContentPack(
            prompts: PromptPack(
                highlightPrompts: ["solo": [HighlightPrompt(id: "first-time", title: "First time", subtitle: "Prompt")]],
                inspirationPrompts: ["Prompt"]
            ),
            expectations: ExpectationPack(presets: [:])
        )
    }

    private func makeViewModel(
        context: ModelContext,
        mediaStore: any MediaStoring,
        transcriber: any Transcribing,
        tripID: UUID
    ) -> ReflectionViewModel {
        ReflectionViewModel(
            tripID: tripID,
            context: context,
            contentPack: makeContentPack(),
            mediaStore: mediaStore,
            gameConfig: .default,
            ai: TemplateAIGenerationService(),
            transcriber: transcriber,
            tripType: .solo,
            onComplete: { _ in }
        )
    }

    @Test func audioReflectionPersistsTranscript() async throws {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())
        let trip = Trip(destination: "Kyoto", country: "Japan", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let store = MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let vm = makeViewModel(
            context: context,
            mediaStore: store,
            transcriber: FakeTranscriber(result: "  A quiet temple at dawn.  "),
            tripID: trip.id
        )

        vm.onAppear()
        vm.bodyKind = .audio
        vm.replaceAudio(with: Data("audio".utf8))
        await vm.transcribeCurrentAudio()

        #expect(vm.transcriptText == "A quiet temple at dawn.")
        #expect(vm.isTranscribing == false)

        vm.step = .photos
        vm.feedSprout()

        let fetched = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        #expect(fetched.transcript == "A quiet temple at dawn.")
    }

    @Test func emptyTranscriptStoredAsNil() async throws {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())
        let trip = Trip(destination: "Kyoto", country: "Japan", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let store = MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let vm = makeViewModel(
            context: context,
            mediaStore: store,
            transcriber: FakeTranscriber(result: "   "),
            tripID: trip.id
        )

        vm.onAppear()
        vm.bodyKind = .audio
        vm.replaceAudio(with: Data("audio".utf8))
        await vm.transcribeCurrentAudio()

        #expect(vm.transcriptText == nil)
        #expect(vm.transcriptionErrorMessage == nil)
    }

    @Test func transcriptionFailureSurfacesErrorMessage() async throws {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())
        let trip = Trip(destination: "Kyoto", country: "Japan", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let store = MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let vm = makeViewModel(
            context: context,
            mediaStore: store,
            transcriber: FailingTranscriber(error: FakeLocalizedTranscriptionError()),
            tripID: trip.id
        )

        vm.onAppear()
        vm.bodyKind = .audio
        vm.replaceAudio(with: Data("audio".utf8))
        await vm.transcribeCurrentAudio()

        #expect(vm.transcriptText == nil)
        #expect(vm.transcriptionErrorMessage == "Transcription failed in tests.")
    }

    @Test func textReflectionPersistsNilTranscript() throws {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())
        let trip = Trip(destination: "Kyoto", country: "Japan", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let store = MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let vm = makeViewModel(
            context: context,
            mediaStore: store,
            transcriber: FakeTranscriber(result: "should be ignored"),
            tripID: trip.id
        )

        vm.onAppear()
        vm.bodyKind = .text
        vm.entryText = "A quiet tram ride."
        // Simulate a stale transcript value that must not leak onto a text reflection.
        vm.transcriptText = "should be ignored"
        vm.step = .photos
        vm.feedSprout()

        let fetched = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        #expect(fetched.transcript == nil)
        #expect(fetched.bodyKind == .text)
    }
}
