import Foundation
import SwiftData
import AVFoundation

@Observable
@MainActor
final class ReflectionViewModel {

    let tripID: UUID
    let context: ModelContext
    let contentPack: ContentPack
    let mediaStore: any MediaStoring
    let tripType: TripType

    var step: Int = 1
    var selectedPrompt: HighlightPrompt?
    var customPromptText: String = ""
    var bodyKind: ReflectionBodyKind = .text
    var entryText: String = ""
    var audioAssetID: UUID?
    var photoAssetIDs: [UUID] = []
    var shuffledPrompts: [HighlightPrompt] = []

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
        let lookup: [String: String] = [
            "first-time":     "You actually went for it!",
            "got-lost":       "Getting lost was the plan all along.",
            "chat-local":     "Those are the conversations that last.",
            "stumbled-place": "The best places find you.",
            "quiet-spot":     "Stillness is underrated.",
            "people-watch":   "You took it all in.",
            "solo-decided":   "That one was all yours.",
            "solo-free":      "Freedom looks good on you.",
            "group-laugh":    "That's the kind you'll talk about for years.",
            "group-close":    "Connection is the whole point.",
            "family-home":    "Home can travel with you.",
            "family-learn":   "The people closest to us still surprise us.",
            "biz-routine":    "Even work trips have moments.",
            "biz-notwork":    "The best part wasn't the meeting."
        ]
        guard let id = selectedPrompt?.id else { return "Tell me more." }
        return lookup[id] ?? "Tell me more."
    }

    private var draftReflection: Reflection?
    private(set) var onDismiss: () -> Void = {}

    init(
        tripID: UUID,
        context: ModelContext,
        contentPack: ContentPack,
        mediaStore: any MediaStoring,
        tripType: TripType,
        onDismiss: @escaping () -> Void
    ) {
        self.tripID = tripID
        self.context = context
        self.contentPack = contentPack
        self.mediaStore = mediaStore
        self.tripType = tripType
        self.onDismiss = onDismiss
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
            photoAssetIDs = existing.photoAssetIDs
        } else if let trip {
            let idx = dayIndex(for: trip)
            let r = Reflection(tripID: tripID, dayIndex: idx, date: Date(), isDraft: true)
            context.insert(r)
            draftReflection = r
        }

        reshuffle(pool: pool)
    }

    func reshuffle() {
        reshuffle(pool: contentPack.prompts.highlights(for: tripType))
    }

    private func reshuffle(pool: [HighlightPrompt]) {
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

    func saveDraft() {
        persistCurrent(commit: false)
        onDismiss()
    }

    func feedSprout() {
        persistCurrent(commit: true)
        onDismiss()
    }

    private func persistCurrent(commit: Bool) {
        guard let r = draftReflection else { return }
        r.highlightPrompt = selectedPrompt?.id ?? customPromptText
        r.bodyKind = bodyKind
        r.text = bodyKind == .text ? entryText : nil
        r.audioAssetID = bodyKind == .audio ? audioAssetID : nil
        r.photoAssetIDs = photoAssetIDs
        r.isDraft = !commit
        if commit { r.xpAwarded = 0 } // Phase 3 wires real XP
        try? context.save()
    }

    private func fetchTrip() -> Trip? {
        var descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tripID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
