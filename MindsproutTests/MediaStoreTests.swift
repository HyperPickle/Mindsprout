import Testing
import Foundation
@testable import Mindsprout

struct MediaStoreTests {

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("mindsprout-test-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func writeReadDeleteRoundTrip() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MediaStore(root: root)
        let payload = Data("a travel moment".utf8)

        let relativePath = try store.write(payload, kind: .photo, fileExtension: "jpg")
        #expect(relativePath.hasPrefix("photos/"))
        #expect(relativePath.hasSuffix(".jpg"))

        let read = try store.read(relativePath: relativePath)
        #expect(read == payload)

        try store.delete(relativePath: relativePath)
        #expect(throws: (any Error).self) {
            _ = try store.read(relativePath: relativePath)
        }
    }

    @Test func audioAndPhotoUseSeparateFolders() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MediaStore(root: root)
        let photo = try store.write(Data([0x1]), kind: .photo, fileExtension: "jpg")
        let audio = try store.write(Data([0x2]), kind: .audio, fileExtension: "m4a")

        #expect(photo.hasPrefix("photos/"))
        #expect(audio.hasPrefix("audio/"))
    }

    @Test func deletingMissingFileIsNoOp() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = MediaStore(root: root)
        // Should not throw for an absent path.
        try store.delete(relativePath: "photos/does-not-exist.jpg")
    }

    @Test func deterministicRelativePathWritePersistsInRequestedFolder() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MediaStore(root: root)
        let payload = Data("static map snapshot".utf8)
        let relativePath = "maps/trips/test-map.jpg"

        try store.write(payload, relativePath: relativePath)

        let read = try store.read(relativePath: relativePath)
        #expect(read == payload)
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(relativePath).path))
    }
}
