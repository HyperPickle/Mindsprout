import Foundation

protocol MediaStoring {
    func url(for relativePath: String) -> URL
    func write(_ data: Data, kind: MediaKind, fileExtension: String) throws -> String
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
        let directory = root.appendingPathComponent(folder, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let relativePath = "\(folder)/\(UUID().uuidString).\(fileExtension)"
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
