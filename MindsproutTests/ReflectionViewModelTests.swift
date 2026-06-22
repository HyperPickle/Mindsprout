import Testing
import Foundation
import SwiftData
@testable import Mindsprout

private struct NoOpTranscriber: Transcribing {
    func transcribe(url: URL) async throws -> String { "" }
}

private struct DelayedAIService: AIGenerationService {
    var delayNanos: UInt64 = 250_000_000
    var insight = GrowthInsight(trait: "Growth", blurb: "Generated insight.")
    var postcard = Postcard(title: "Generated postcard", body: "Generated postcard body.")

    func generateTripTheme(_ request: TripThemeRequest) async -> String { "Theme" }
    func generateHeadline(recentReflectionTexts: [String]) async -> String { recentReflectionTexts.first ?? "" }
    func generateMoodTags(_ context: ReflectionContext) async -> [String] { ["Joy"] }

    func generateGrowthInsight(_ context: ReflectionContext) async -> GrowthInsight {
        try? await Task.sleep(nanoseconds: delayNanos)
        return insight
    }

    func generatePostcard(_ context: ReflectionContext) async -> Postcard {
        try? await Task.sleep(nanoseconds: delayNanos)
        return postcard
    }
}

private enum SaveFailure: Error {
    case failed
}

@MainActor
private final class SaveController {
    private(set) var callCount = 0
    var failuresRemaining: Int

    init(failuresRemaining: Int) {
        self.failuresRemaining = failuresRemaining
    }

    func save() throws {
        callCount += 1
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw SaveFailure.failed
        }
    }
}

@MainActor
struct ReflectionViewModelTests {

    private func makeContentPack() -> ContentPack {
        ContentPack(
            prompts: PromptPack(
                highlightPrompts: [
                    "solo": [
                        HighlightPrompt(id: "first-time", title: "First time", subtitle: "Prompt"),
                        HighlightPrompt(id: "shared-meal", title: "Shared meal", subtitle: "Prompt"),
                        HighlightPrompt(id: "sunrise", title: "Sunrise", subtitle: "Prompt"),
                        HighlightPrompt(id: "detour", title: "Detour", subtitle: "Prompt"),
                        HighlightPrompt(id: "locals", title: "Locals", subtitle: "Prompt")
                    ]
                ],
                inspirationPrompts: ["Prompt"]
            ),
            expectations: ExpectationPack(presets: [:])
        )
    }

    private func makeViewModel(
        context: ModelContext,
        mediaStore: any MediaStoring,
        tripID: UUID,
        ai: any AIGenerationService = TemplateAIGenerationService(),
        onComplete: @escaping (ReflectionCompletion) -> Void = { _ in },
        saveAction: (() throws -> Void)? = nil
    ) -> ReflectionViewModel {
        ReflectionViewModel(
            tripID: tripID,
            context: context,
            contentPack: makeContentPack(),
            mediaStore: mediaStore,
            gameConfig: .default,
            ai: ai,
            transcriber: NoOpTranscriber(),
            tripType: .solo,
            onComplete: onComplete,
            saveAction: saveAction
        )
    }

    private func makeTrip(in context: ModelContext, destination: String = "Lisbon") throws -> Trip {
        let trip = Trip(destination: destination, country: "Portugal", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()
        return trip
    }

    private func makeMediaStore() -> MediaStore {
        MediaStore(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
    }

    @Test func feedSproutPersistsRewardAndCompletesAfterRewardCTA() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)
        var completions: [ReflectionCompletion] = []

        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id,
            onComplete: { completions.append($0) }
        )

        vm.onAppear()
        vm.step = .photos
        vm.moodTags = ["Joyful"]
        vm.entryText = "A quiet tram ride."
        vm.feedSprout()

        let reflection = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        #expect(reflection.moodTags == ["Joyful"])
        #expect(reflection.isDraft == false)
        #expect(reflection.xpAwarded == 10)
        #expect(vm.step == .reward)
        #expect(vm.rewardState?.xpAwarded == 10)
        #expect(completions.isEmpty)

        let sprout = try #require(context.fetch(FetchDescriptor<Sprout>()).first)
        #expect(sprout.xp == 10)
        #expect(sprout.currency == 10)

        vm.completeReward()

        #expect(completions == [.finish])
    }

    @Test func feedSproutDoesNotAwardTwiceForSameReflection() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)

        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id
        )

        vm.onAppear()
        vm.step = .photos
        vm.entryText = "A quiet tram ride."
        vm.feedSprout()
        vm.feedSprout()

        let reflection = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        let sprout = try #require(context.fetch(FetchDescriptor<Sprout>()).first)
        #expect(reflection.xpAwarded == 10)
        #expect(sprout.xp == 10)
        #expect(sprout.currency == 10)
        #expect(vm.rewardState?.xpAwarded == 10)
    }

    @Test func failedSaveRollsBackReflectionAndSproutMutations() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)
        let sprout = Sprout(xp: 40, level: 3, currentStageIndex: 0, currency: 25, state: .hungry)
        context.insert(sprout)
        try context.save()

        let saveController = SaveController(failuresRemaining: 1)
        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id,
            saveAction: { try saveController.save() }
        )

        vm.onAppear()
        vm.step = .photos
        vm.entryText = "Storm light over the river."
        vm.feedSprout()

        let reflection = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        #expect(reflection.isDraft == true)
        #expect(reflection.xpAwarded == 0)
        #expect(vm.step == .photos)
        #expect(vm.rewardState == nil)
        #expect(vm.submissionErrorMessage == "We couldn’t save this reflection. Try again.")

        let fetchedSprout = try #require(context.fetch(FetchDescriptor<Sprout>()).first)
        #expect(fetchedSprout.xp == 40)
        #expect(fetchedSprout.currency == 25)
        #expect(fetchedSprout.level == 3)
        #expect(fetchedSprout.state == .hungry)
    }

    @Test func failedSaveCanRetryWithoutDoubleAwarding() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)
        let saveController = SaveController(failuresRemaining: 1)

        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id,
            saveAction: { try saveController.save() }
        )

        vm.onAppear()
        vm.step = .photos
        vm.entryText = "Late ferry, warm lights."
        vm.feedSprout()

        #expect(vm.rewardState == nil)
        #expect(vm.submissionErrorMessage == "We couldn’t save this reflection. Try again.")

        vm.feedSprout()

        let reflection = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        let sprout = try #require(context.fetch(FetchDescriptor<Sprout>()).first)
        #expect(saveController.callCount == 2)
        #expect(reflection.isDraft == false)
        #expect(reflection.xpAwarded == 10)
        #expect(sprout.xp == 10)
        #expect(vm.step == .reward)
        #expect(vm.submissionErrorMessage == nil)
    }

    @Test func milestoneRewardUsesFallbackPresentationUntilAICompletes() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context, destination: "Kyoto")
        let sprout = Sprout(xp: 70, level: 4, currentStageIndex: 0, currency: 0, state: .idle)
        context.insert(sprout)
        try context.save()

        var completions: [ReflectionCompletion] = []
        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id,
            ai: DelayedAIService(),
            onComplete: { completions.append($0) }
        )

        vm.onAppear()
        vm.step = .photos
        vm.customPromptText = "Temple bells at dawn"
        vm.entryText = "The city was silent except for the bells."
        vm.feedSprout()

        let expectedFallback = LevelUpPresentation.fallback(
            destination: "Kyoto",
            previousLevel: 4,
            newLevel: 5,
            context: ReflectionContext(
                tripType: .solo,
                destination: "Kyoto",
                highlightPrompt: "Temple bells at dawn",
                text: "The city was silent except for the bells.",
                hasPhoto: false,
                hasAudio: false
            )
        )

        let rewardState = try #require(vm.rewardState)
        let milestonePresentation = try #require(rewardState.milestonePresentation)
        #expect(rewardState.isMilestone)
        #expect(milestonePresentation == expectedFallback)

        vm.completeReward()

        #expect(completions == [.milestone(expectedFallback)])
    }

    @Test func completedReflectionSkipsRewardScreenInsteadOfShowingZeroXP() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)
        let reflection = Reflection(
            tripID: trip.id,
            dayIndex: 1,
            date: .now,
            highlightPrompt: "sunrise",
            bodyKind: .text,
            text: "Already saved",
            isDraft: false
        )
        reflection.xpAwarded = 10
        context.insert(reflection)
        try context.save()

        var completions: [ReflectionCompletion] = []
        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id,
            onComplete: { completions.append($0) }
        )

        vm.onAppear()
        vm.step = .photos
        vm.entryText = "Already saved"
        vm.feedSprout()

        #expect(vm.rewardState == nil)
        #expect(vm.step == .photos)
        #expect(completions == [.finish])
    }

    @Test func reduceMotionAnimationPlanShowsFinalXPImmediately() {
        let reducedMotionPlan = ReflectionRewardAnimationPlan(reduceMotion: true, awardedXP: 10)
        #expect(reducedMotionPlan.initialXP == 10)
        #expect(reducedMotionPlan.finalXP == 10)
        #expect(reducedMotionPlan.shouldAnimateXP == false)
        #expect(reducedMotionPlan.shouldAnimateSprout == false)

        let standardPlan = ReflectionRewardAnimationPlan(reduceMotion: false, awardedXP: 10)
        #expect(standardPlan.initialXP == 0)
        #expect(standardPlan.finalXP == 10)
        #expect(standardPlan.shouldAnimateXP)
        #expect(standardPlan.shouldAnimateSprout)
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

    @Test func onAppearClearsAbandonedDraftPhotoButResumesText() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = Trip(destination: "Oslo", country: "Norway", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)

        let mediaRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = MediaStore(root: mediaRoot)
        let path = try store.write(Data("photo".utf8), kind: .photo, fileExtension: "jpg")
        let asset = MediaAsset(kind: .photo, relativePath: path)
        context.insert(asset)

        let draft = Reflection(tripID: trip.id, date: .now, text: "Resumed thought", isDraft: true)
        draft.photoAssetIDs = [asset.id]
        context.insert(draft)
        try context.save()

        #expect(FileManager.default.fileExists(atPath: store.url(for: path).path))

        let vm = makeViewModel(context: context, mediaStore: store, tripID: trip.id)
        vm.onAppear()

        #expect(vm.photoAssetIDs.isEmpty)
        #expect(vm.entryText == "Resumed thought")
        #expect(draft.photoAssetIDs.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: store.url(for: path).path))
        #expect(try context.fetch(FetchDescriptor<MediaAsset>()).isEmpty)
    }

    @Test func discardDraftRemovesDraftRecordAndAllCapturedMedia() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)

        let mediaRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = MediaStore(root: mediaRoot)
        let vm = makeViewModel(context: context, mediaStore: store, tripID: trip.id)

        vm.onAppear()
        vm.entryText = "A draft in progress"

        // Stage a photo and an audio recording, as the creation steps would.
        let photoPath = try store.write(Data("photo".utf8), kind: .photo, fileExtension: "jpg")
        let photoAsset = MediaAsset(kind: .photo, relativePath: photoPath)
        context.insert(photoAsset)
        vm.photoAssetIDs = [photoAsset.id]

        vm.replaceAudio(with: Data("audio".utf8))
        let audioID = try #require(vm.audioAssetID)
        let audioPath = try #require(MediaImage.relativePath(for: audioID, in: context))

        #expect(FileManager.default.fileExists(atPath: store.url(for: photoPath).path))
        #expect(FileManager.default.fileExists(atPath: store.url(for: audioPath).path))

        vm.discardDraft()

        #expect(try context.fetch(FetchDescriptor<Reflection>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MediaAsset>()).isEmpty)
        #expect(!FileManager.default.fileExists(atPath: store.url(for: photoPath).path))
        #expect(!FileManager.default.fileExists(atPath: store.url(for: audioPath).path))
        #expect(vm.audioAssetID == nil)
        #expect(vm.photoAssetIDs.isEmpty)
    }

    @Test func discardDraftDoesNotDeleteSubmittedReflection() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = try makeTrip(in: context)

        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id
        )

        vm.onAppear()
        vm.step = .photos
        vm.entryText = "Already fed to Sprout."
        vm.feedSprout()

        vm.discardDraft()

        let reflection = try #require(context.fetch(FetchDescriptor<Reflection>()).first)
        #expect(reflection.isDraft == false)
        #expect(reflection.text == "Already fed to Sprout.")
    }

    @Test func reshuffleClearsSelectedPrompt() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let trip = Trip(destination: "Tokyo", country: "Japan", startDate: .now, endDate: .now, type: .solo)
        context.insert(trip)
        try context.save()

        let vm = makeViewModel(
            context: context,
            mediaStore: makeMediaStore(),
            tripID: trip.id
        )

        vm.onAppear()
        let prompt = try #require(vm.shuffledPrompts.first)
        vm.selectPrompt(prompt)

        vm.reshuffle()

        #expect(vm.selectedPrompt == nil)
    }
}
