import Foundation

protocol MediaStoring {
    func url(for relativePath: String) -> URL
    func write(_ data: Data, kind: MediaKind, fileExtension: String) throws -> String
    func write(_ data: Data, relativePath: String) throws
    func read(relativePath: String) throws -> Data
    func delete(relativePath: String) throws
}

final class MediaStore: MediaStoring {
    let root: URL

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
        let relativePath = "\(folder)/\(UUID().uuidString).\(fileExtension)"
        try write(data, relativePath: relativePath)
        return relativePath
    }

    func write(_ data: Data, relativePath: String) throws {
        let fileURL = url(for: relativePath)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
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
