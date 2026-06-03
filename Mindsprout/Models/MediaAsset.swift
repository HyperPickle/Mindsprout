//
//  MediaAsset.swift
//  Mindsprout
//
//  Metadata record for a photo or audio file. The bytes live as a file in the
//  app container (Documents/media/...) — never as a blob in the store. The
//  model holds only a container-relative path, resolved by `MediaStore`.
//

import Foundation
import SwiftData

@Model
final class MediaAsset {
    var id: UUID = UUID()

    var kind: MediaKind = MediaKind.photo

    /// Path relative to the media root (e.g. `photos/<uuid>.jpg`). Resolved to an
    /// absolute URL via `MediaStore.url(for:)`. Storing a relative path keeps the
    /// reference valid across app-container path changes and is sync-friendly.
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
