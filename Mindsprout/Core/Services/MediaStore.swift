//
//  MediaStore.swift
//  Mindsprout
//
//  Reads/writes photo and audio files in the app container. SwiftData models
//  store only the container-relative path (see `MediaAsset`); this service is
//  the single place that resolves those to absolute URLs and owns the on-disk
//  layout (Documents/media/{photos,audio}).
//

import Foundation

/// Abstracts media file storage so features never touch the filesystem
/// directly and tests can substitute a temporary root.
protocol MediaStoring {
    /// Absolute URL for a stored asset's container-relative path.
    func url(for relativePath: String) -> URL
    /// Persists data for the given kind, returning the relative path to store.
    func write(_ data: Data, kind: MediaKind, fileExtension: String) throws -> String
    /// Reads bytes for a stored relative path.
    func read(relativePath: String) throws -> Data
    /// Removes the file at a relative path (no-op if absent).
    func delete(relativePath: String) throws
}

final class MediaStore: MediaStoring {
    /// Root directory containing the `photos/` and `audio/` subfolders.
    let root: URL

    /// - Parameter root: media root. Defaults to `Documents/media`. Tests pass a
    ///   temporary directory.
    init(root: URL? = nil) {
        if let root {
            self.root = root
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.root = documents.appendingPathComponent("media", isDirectory: true)
        }
    }

    private func subfolder(for kind: MediaKind) -> String {
        switch kind {
        case .photo: return "photos"
        case .audio: return "audio"
        }
    }

    func url(for relativePath: String) -> URL {
        root.appendingPathComponent(relativePath, isDirectory: false)
    }

    func write(_ data: Data, kind: MediaKind, fileExtension: String) throws -> String {
        let folder = subfolder(for: kind)
        let directory = root.appendingPathComponent(folder, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let relativePath = "\(folder)/\(fileName)"
        try data.write(to: url(for: relativePath), options: .atomic)
        return relativePath
    }

    func read(relativePath: String) throws -> Data {
        try Data(contentsOf: url(for: relativePath))
    }

    func delete(relativePath: String) throws {
        let fileURL = url(for: relativePath)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
