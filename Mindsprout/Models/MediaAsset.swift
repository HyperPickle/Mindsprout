import Foundation
import SwiftData

@Model
final class MediaAsset {
    var id: UUID = UUID()

    var kind: MediaKind = MediaKind.photo
    // Relative to the media root; resolved via MediaStore.url(for:).
    var relativePath: String = ""

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        kind: MediaKind,
        relativePath: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.relativePath = relativePath
        self.createdAt = createdAt
    }
}
