import Foundation
import SwiftData
import AVFoundation

enum ReflectionStep: Int, CaseIterable, Sendable {
    case highlight
    case entry
    case photos
    case reward
}

enum ReflectionCompletion: Sendable, Equatable {
    case finish
    case milestone(LevelUpPresentation)
}

struct ReflectionRewardState: Sendable, Equatable {
    var xpAwarded: Int
    var milestonePresentation: LevelUpPresentation?

    var completion: ReflectionCompletion {
        if let milestonePresentation {
            return .milestone(milestonePresentation)
        }
        return .finish
    }

    var isMilestone: Bool {
        milestonePresentation != nil
    }
}

@Observable
@MainActor
final class ReflectionViewModel {

    let tripID: UUID
    let context: ModelContext
    let contentPack: ContentPack
    let mediaStore: any MediaStoring
    let gameConfig: GameConfig
    let ai: any AIGenerationService
    let transcriber: any Transcribing
    let tripType: TripType
    private let saveAction: () throws -> Void

    var step: ReflectionStep = .highlight
    var selectedPrompt: HighlightPrompt?
    var customPromptText: String = ""
    var bodyKind: ReflectionBodyKind = .text
    var entryText: String = ""
    var audioAssetID: UUID?
    var transcriptText: String?
    var isTranscribing: Bool = false
    var transcriptionErrorMessage: String?
    var photoAssetIDs: [UUID] = []
    var moodTags: [String] = []
    var shuffledPrompts: [HighlightPrompt] = []
    var rewardState: ReflectionRewardState?
    var submissionErrorMessage: String?
    var isSubmitting = false

    var inspirationIndex: Int = 0
    var inspirationPrompt: String {
        let prompts = contentPack.prompts.inspirationPrompts
        guard !prompts.isEmpty else { return "" }
        return prompts[inspirationIndex % prompts.count]
    }

    var canContinueStep1: Bool {
        selectedPrompt != nil || !customPromptText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canContinueStep2: Bool {
        switch bodyKind {
        case .text: return !entryText.trimmingCharacters(in: .whitespaces).isEmpty
        case .audio: return audioAssetID != nil
        }
    }

    var affirmationHeadline: String {
        if let prompt = selectedPrompt { return prompt.title }
        return customPromptText
    }

    private var draftReflection: Reflection?
    private(set) var onComplete: (ReflectionCompletion) -> Void = { _ in }

    private struct PendingMilestoneReward {
        var destination: String
        var previousLevel: Int
        var newLevel: Int
        var context: ReflectionContext
    }

    private struct ReflectionSnapshot {
        var highlightPrompt: String
        var bodyKind: ReflectionBodyKind
        var text: String?
        var audioAssetID: UUID?
        var transcript: String?
        var photoAssetIDs: [UUID]
        var moodTags: [String]
        var isDraft: Bool
        var xpAwarded: Int

        init(reflection: Reflection) {
            highlightPrompt = reflection.highlightPrompt
            bodyKind = reflection.bodyKind
            text = reflection.text
            audioAssetID = reflection.audioAssetID
            transcript = reflection.transcript
            photoAssetIDs = reflection.photoAssetIDs
            moodTags = reflection.moodTags
            isDraft = reflection.isDraft
            xpAwarded = reflection.xpAwarded
        }

        func restore(to reflection: Reflection) {
            reflection.highlightPrompt = highlightPrompt
            reflection.bodyKind = bodyKind
            reflection.text = text
            reflection.audioAssetID = audioAssetID
            reflection.transcript = transcript
            reflection.photoAssetIDs = photoAssetIDs
            reflection.moodTags = moodTags
            reflection.isDraft = isDraft
            reflection.xpAwarded = xpAwarded
        }
    }

    private struct SproutSnapshot {
        var xp: Int
        var level: Int
        var currentStageIndex: Int
        var currency: Int
        var state: SproutState

        init(sprout: Sprout) {
            xp = sprout.xp
            level = sprout.level
            currentStageIndex = sprout.currentStageIndex
            currency = sprout.currency
            state = sprout.state
        }

        func restore(to sprout: Sprout) {
            sprout.xp = xp
            sprout.level = level
            sprout.currentStageIndex = currentStageIndex
            sprout.currency = currency
            sprout.state = state
        }
    }

    init(
        tripID: UUID,
        context: ModelContext,
        contentPack: ContentPack,
        mediaStore: any MediaStoring,
        gameConfig: GameConfig,
        ai: any AIGenerationService,
        transcriber: any Transcribing,
        tripType: TripType,
        onComplete: @escaping (ReflectionCompletion) -> Void,
        saveAction: (() throws -> Void)? = nil
    ) {
        self.tripID = tripID
        self.context = context
        self.contentPack = contentPack
        self.mediaStore = mediaStore
        self.gameConfig = gameConfig
        self.ai = ai
        self.transcriber = transcriber
        self.tripType = tripType
        self.onComplete = onComplete
        self.saveAction = saveAction ?? { try context.save() }
    }

    func onAppear() {
        let pool = contentPack.prompts.highlights(for: tripType)

        // Load or create today's draft
        let trip = fetchTrip()
        if let trip, let existing = todaysReflection(for: trip, in: context) {
            draftReflection = existing
            // Restore state from existing draft
            if let prompt = pool.first(where: { $0.id == existing.highlightPrompt }) {
                selectedPrompt = prompt
            } else if !existing.highlightPrompt.isEmpty {
                customPromptText = existing.highlightPrompt
            }
            entryText = existing.text ?? ""
            bodyKind = existing.bodyKind
            audioAssetID = existing.audioAssetID
            transcriptText = existing.transcript
            moodTags = existing.moodTags
            if existing.isDraft {
                for id in existing.photoAssetIDs { deleteMediaAsset(id: id) }
                existing.photoAssetIDs = []
                photoAssetIDs = []
            } else {
                photoAssetIDs = existing.photoAssetIDs
            }
        } else if let trip {
            let idx = dayIndex(for: trip)
            let r = Reflection(tripID: tripID, dayIndex: idx, date: Date(), isDraft: true)
            context.insert(r)
            draftReflection = r
        }

        reshuffle(pool: pool, clearingSelection: false)
    }

    func reshuffle() {
        reshuffle(pool: contentPack.prompts.highlights(for: tripType), clearingSelection: true)
    }

    private func reshuffle(pool: [HighlightPrompt], clearingSelection: Bool) {
        if clearingSelection {
            selectedPrompt = nil
        }

        guard pool.count >= 4 else {
            shuffledPrompts = pool.shuffled()
            return
        }
        var candidates = pool.filter { p in !(shuffledPrompts.contains { $0.id == p.id }) }
        if candidates.count < 4 { candidates = pool }
        shuffledPrompts = Array(candidates.shuffled().prefix(4))
    }

    func nextInspiration() {
        let count = contentPack.prompts.inspirationPrompts.count
        guard count > 0 else { return }
        inspirationIndex = (inspirationIndex + 1) % count
    }

    func selectPrompt(_ prompt: HighlightPrompt) {
        selectedPrompt = prompt
        customPromptText = ""
    }

    func clearPromptSelection() {
        selectedPrompt = nil
    }

    func feedSprout() {
        guard step == .photos, !isSubmitting else { return }

        isSubmitting = true
        submissionErrorMessage = nil

        do {
            let reward = try persistCurrent()
            isSubmitting = false

            guard let reward else {
                onComplete(.finish)
                return
            }

            rewardState = reward
            step = .reward

            guard reward.isMilestone else { return }
            Task { @MainActor in
                await refreshMilestonePresentation()
            }
        } catch {
            isSubmitting = false
            submissionErrorMessage = Self.persistenceErrorMessage
        }
    }

    func completeReward() {
        guard let rewardState else {
            onComplete(.finish)
            return
        }

        self.rewardState = nil
        onComplete(rewardState.completion)
    }

    func replaceAudio(with data: Data, fileExtension: String = "m4a") {
        clearAudioDraft()
        guard let path = try? mediaStore.write(data, kind: .audio, fileExtension: fileExtension) else { return }
        let asset = MediaAsset(kind: .audio, relativePath: path)
        context.insert(asset)
        audioAssetID = asset.id
    }

    /// Discards an in-progress reflection: removes the draft record and every
    /// piece of media captured during this session (staged or already attached),
    /// including the underlying files. No-op once the reflection has been
    /// submitted, so a completed reflection can never be destroyed here.
    func discardDraft() {
        guard let r = draftReflection, r.isDraft else { return }

        var mediaIDs = Set(r.photoAssetIDs)
        mediaIDs.formUnion(photoAssetIDs)
        if let id = r.audioAssetID { mediaIDs.insert(id) }
        if let id = audioAssetID { mediaIDs.insert(id) }
        for id in mediaIDs { deleteMediaAsset(id: id) }

        context.delete(r)
        draftReflection = nil
        audioAssetID = nil
        photoAssetIDs = []
        try? saveAction()
    }

    func clearAudioDraft() {
        guard let audioAssetID else { return }
        deleteMediaAsset(id: audioAssetID)
        self.audioAssetID = nil
        transcriptText = nil
        transcriptionErrorMessage = nil
        isTranscribing = false
    }

    /// Transcribes the saved audio recording on-device and stores the result
    /// in `transcriptText` so it can be shown in the preview and persisted with
    /// the reflection. Failures preserve a user-facing error message so the UI
    /// can explain why a transcript is unavailable.
    func transcribeCurrentAudio() async {
        guard let audioAssetID,
              let path = MediaImage.relativePath(for: audioAssetID, in: context) else { return }
        let url = mediaStore.url(for: path)
        isTranscribing = true
        transcriptionErrorMessage = nil
        defer { isTranscribing = false }
        do {
            let result = try await transcriber.transcribe(url: url)
            let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
            transcriptText = trimmed.isEmpty ? nil : trimmed
        } catch {
            transcriptText = nil
            transcriptionErrorMessage = Self.transcriptionErrorMessage(for: error)
        }
    }

    @discardableResult
    private func persistCurrent() throws -> ReflectionRewardState? {
        guard let r = draftReflection else { return nil }

        let reflectionSnapshot = ReflectionSnapshot(reflection: r)
        var sproutSnapshot: SproutSnapshot?
        var createdSprout: Sprout?
        var pendingMilestoneReward: PendingMilestoneReward?
        var newlyAwardedXP = 0

        r.highlightPrompt = selectedPrompt?.id ?? customPromptText
        r.bodyKind = bodyKind
        r.text = bodyKind == .text ? entryText : nil
        r.audioAssetID = bodyKind == .audio ? audioAssetID : nil
        r.transcript = bodyKind == .audio ? transcriptText : nil
        r.photoAssetIDs = photoAssetIDs
        r.moodTags = moodTags
        r.isDraft = false

        if r.xpAwarded == 0 {
            let (sprout, didCreate) = fetchOrCreateSprout()
            createdSprout = didCreate ? sprout : nil
            sproutSnapshot = SproutSnapshot(sprout: sprout)
            let result = SproutProgressionEngine(config: gameConfig).applyFeed(to: sprout)
            r.xpAwarded = result.xpAwarded
            newlyAwardedXP = result.xpAwarded
            if result.shouldPresentMilestoneReward, let trip = fetchTrip() {
                let context = ReflectionContext(
                    tripType: trip.type,
                    destination: trip.destination,
                    highlightPrompt: r.highlightPrompt,
                    text: r.text,
                    hasPhoto: !r.photoAssetIDs.isEmpty,
                    hasAudio: r.audioAssetID != nil
                )
                pendingMilestoneReward = PendingMilestoneReward(
                    destination: trip.destination,
                    previousLevel: result.previousLevel,
                    newLevel: result.newLevel,
                    context: context
                )
            }
        }

        do {
            try saveAction()
        } catch {
            reflectionSnapshot.restore(to: r)
            if let createdSprout {
                context.delete(createdSprout)
            } else if let sproutSnapshot, let sprout = try? fetchExistingSprout() {
                sproutSnapshot.restore(to: sprout)
            }
            throw error
        }

        guard newlyAwardedXP > 0 else { return nil }

        let rewardState = ReflectionRewardState(
            xpAwarded: newlyAwardedXP,
            milestonePresentation: pendingMilestoneReward.map { pending in
                LevelUpPresentation.fallback(
                    destination: pending.destination,
                    previousLevel: pending.previousLevel,
                    newLevel: pending.newLevel,
                    context: pending.context
                )
            }
        )
        return rewardState
    }

    private func fetchTrip() -> Trip? {
        var descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tripID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchExistingSprout() throws -> Sprout? {
        var descriptor = FetchDescriptor<Sprout>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchOrCreateSprout() -> (Sprout, Bool) {
        if let existingSprout = try? fetchExistingSprout() {
            return (existingSprout, false)
        }
        let sprout = Sprout()
        context.insert(sprout)
        return (sprout, true)
    }

    private func deleteMediaAsset(id: UUID) {
        var descriptor = FetchDescriptor<MediaAsset>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let asset = try? context.fetch(descriptor).first else { return }
        try? mediaStore.delete(relativePath: asset.relativePath)
        context.delete(asset)
        try? context.save()
    }

    private static func transcriptionErrorMessage(for error: Error) -> String {
        if let localized = (error as? LocalizedError)?.errorDescription,
           !localized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return localized
        }
        return String(localized: "Couldn’t transcribe this recording.")
    }

    private func refreshMilestonePresentation() async {
        guard let rewardState,
              let fallbackPresentation = rewardState.milestonePresentation,
              let trip = fetchTrip()
        else { return }
        let rewardPresentationID = fallbackPresentation.id

        let reflectionText = bodyKind == .text ? entryText : nil
        let rewardContext = ReflectionContext(
            tripType: trip.type,
            destination: trip.destination,
            highlightPrompt: selectedPrompt?.id ?? customPromptText,
            text: reflectionText,
            hasPhoto: !photoAssetIDs.isEmpty,
            hasAudio: audioAssetID != nil
        )

        let insight = await ai.generateGrowthInsight(rewardContext)
        let postcard = await ai.generatePostcard(rewardContext)

        guard self.rewardState?.milestonePresentation?.id == rewardPresentationID else { return }
        self.rewardState = ReflectionRewardState(
            xpAwarded: rewardState.xpAwarded,
            milestonePresentation: LevelUpPresentation(
                id: fallbackPresentation.id,
                destination: fallbackPresentation.destination,
                previousLevel: fallbackPresentation.previousLevel,
                newLevel: fallbackPresentation.newLevel,
                insight: insight,
                postcard: postcard
            )
        )
    }

    private static let persistenceErrorMessage = String(localized: "We couldn’t save this reflection. Try again.")
}
