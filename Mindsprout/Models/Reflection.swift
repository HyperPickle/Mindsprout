import Foundation
import SwiftData

@Model
final class Reflection {
    var id: UUID = UUID()
    var tripID: UUID = UUID()
    var dayIndex: Int = 1
    var date: Date = Date()
    var highlightPrompt: String = ""
    var locationLabel: String?
    var bodyKind: ReflectionBodyKind = ReflectionBodyKind.text
    var text: String?
    var audioAssetID: UUID?
    /// On-device transcript of the audio recording (when bodyKind == .audio).
    /// Generated locally after recording; used by future AI features.
    var transcript: String?
    var photoAssetIDs: [UUID] = []
    var moodTags: [String] = []
    var isDraft: Bool = true
    var xpAwarded: Int = 0
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        tripID: UUID,
        dayIndex: Int = 1,
        date: Date = Date(),
        highlightPrompt: String = "",
        locationLabel: String? = nil,
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
        self.locationLabel = locationLabel
        self.bodyKind = bodyKind
        self.text = text
        self.audioAssetID = audioAssetID
        self.photoAssetIDs = photoAssetIDs
        self.isDraft = isDraft
        self.createdAt = createdAt
    }
}
