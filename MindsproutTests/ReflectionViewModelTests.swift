import Testing
import Foundation
import SwiftData
@testable import Mindsprout

@MainActor
struct ReflectionViewModelTests {

    private func makeContentPack() -> ContentPack {
        ContentPack(
            prompts: PromptPack(
                highlightPrompts: [
                    "solo": [HighlightPrompt(id: "first-time", title: "First time", subtitle: "Prompt")]
                ],
                inspirationPrompts: ["Prompt"]
            ),
            expectations: ExpectationPack(presets: [:])
        )
    }

    private func makeViewModel(
        context: ModelContext,
        mediaStore: any MediaStoring,
        tripID: UUID
    ) -> ReflectionViewModel {
        ReflectionViewModel(
            tripID: tripID,
            context: context,
            contentPack: makeContentPack(),
            mediaStore: mediaStore,
            gameConfig: .default,
            ai: TemplateAIGenerationService(),
            tripType: .solo,
            onDismiss: {}
        )
    }

    @Test func feedSproutPersistsUpdatedMoodTags() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = Trip(destination: "Lisbon", country: "Portugal", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let vm = makeViewModel(
            context: context,
            mediaStore: MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)),
            tripID: trip.id
        )

        vm.onAppear()
        vm.moodTags = ["Joyful"]
        vm.entryText = "A quiet tram ride."
        vm.feedSprout()

        let fetched = try context.fetch(FetchDescriptor<Reflection>()).first
        #expect(fetched?.moodTags == ["Joyful"])
        #expect(fetched?.isDraft == false)
        #expect(fetched?.xpAwarded == 10)

        let sprout = try #require(context.fetch(FetchDescriptor<Sprout>()).first)
        #expect(sprout.xp == 10)
        #expect(sprout.currency == 10)
    }

    @Test func feedSproutDoesNotAwardTwiceForSameReflection() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = Trip(destination: "Lisbon", country: "Portugal", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let vm = makeViewModel(
            context: context,
            mediaStore: MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)),
            tripID: trip.id
        )

        vm.onAppear()
        vm.entryText = "A quiet tram ride."
        vm.feedSprout()
        vm.feedSprout()

        let reflection = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        let sprout = try #require(context.fetch(FetchDescriptor<Sprout>()).first)
        #expect(reflection.xpAwarded == 10)
        #expect(sprout.xp == 10)
        #expect(sprout.currency == 10)
    }

    @Test func clearAudioDraftRemovesStoredAssetAndKeepsOtherDraftState() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = Trip(destination: "Seoul", country: "South Korea", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let mediaRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = MediaStore(root: mediaRoot)
        let vm = makeViewModel(context: context, mediaStore: store, tripID: trip.id)

        vm.onAppear()
        vm.entryText = "Still intact"
        vm.moodTags = ["Calm"]
        vm.replaceAudio(with: Data("audio".utf8))

        let assetID = try #require(vm.audioAssetID)
        let path = try #require(MediaImage.relativePath(for: assetID, in: context))
        #expect(FileManager.default.fileExists(atPath: store.url(for: path).path))

        vm.clearAudioDraft()

        #expect(vm.audioAssetID == nil)
        #expect(vm.entryText == "Still intact")
        #expect(vm.moodTags == ["Calm"])
        #expect(!FileManager.default.fileExists(atPath: store.url(for: path).path))
        #expect(try context.fetch(FetchDescriptor<MediaAsset>()).isEmpty)
    }
}
