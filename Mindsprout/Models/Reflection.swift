//
//  Reflection.swift
//  Mindsprout
//
//  Skeletal Phase 0 stub. One reflection per calendar day per active trip
//  (soft rule, enforced in Phase 2). Body is EITHER typed text OR an audio
//  recording; photos may attach to either. Finalized in Phase 2.
//

import Foundation
import SwiftData

@Model
final class Reflection {
    var id: UUID = UUID()

    /// The owning `Trip.id`.
    var tripID: UUID = UUID()

    /// 1-based day number derived from the trip start date.
    var dayIndex: Int = 1
    var date: Date = Date()

    /// The chosen highlight prompt this entry responds to.
    var highlightPrompt: String = ""

    var bodyKind: ReflectionBodyKind = ReflectionBodyKind.text

    /// Typed body (≤200 chars, enforced in the entry UI), when `bodyKind == .text`.
    var text: String?
    /// `MediaAsset.id` of the recording, when `bodyKind == .audio`.
    var audioAssetID: UUID?

    /// `MediaAsset.id`s of attached photos.
    var photoAssetIDs: [UUID] = []

    /// AI-derived mood tags; empty until generated.
    var moodTags: [String] = []

    /// Drafts persist but award no XP. Feeding the Sprout commits + awards XP.
    var isDraft: Bool = true
    /// XP granted when committed (0 while a draft). Source of truth: `GameConfig`.
    var xpAwarded: Int = 0

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        tripID: UUID,
        dayIndex: Int = 1,
        date: Date = Date(),
        highlightPrompt: String = "",
        bodyKind: ReflectionBodyKind = .text,
        text: String? = nil,
        audioAssetID: UUID? = nil,
        photoAssetIDs: [UUID] = [],
        isDraft: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tripID = tripID
        self.dayIndex = dayIndex
        self.date = date
        self.highlightPrompt = highlightPrompt
        self.bodyKind = bodyKind
        self.text = text
        self.audioAssetID = audioAssetID
        self.photoAssetIDs = photoAssetIDs
        self.isDraft = isDraft
        self.createdAt = createdAt
    }
}
