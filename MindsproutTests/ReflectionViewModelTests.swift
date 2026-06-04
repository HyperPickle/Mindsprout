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
            tripType: .solo,
            onDismiss: {}
        )
    }

    @Test func loadsAndPersistsMoodTagsForDraftReflection() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = Trip(destination: "Kyoto", country: "Japan", startDate: .now, endDate: .now, type: .solo)
        let reflection = Reflection(
            tripID: trip.id,
            dayIndex: 1,
            date: .now,
            highlightPrompt: "first-time",
            isDraft: true
        )
        reflection.moodTags = ["Serene", "Curious"]
        context.insert(trip)
        context.insert(reflection)
        try context.save()

        let vm = makeViewModel(
            context: context,
            mediaStore: MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)),
            tripID: trip.id
        )

        vm.onAppear()
        #expect(vm.moodTags == ["Serene", "Curious"])

        vm.moodTags = ["Grounded", "Open"]
        vm.saveDraft()

        let fetched = try context.fetch(FetchDescriptor<Reflection>()).first
        #expect(fetched?.moodTags == ["Grounded", "Open"])
        #expect(fetched?.isDraft == true)
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
