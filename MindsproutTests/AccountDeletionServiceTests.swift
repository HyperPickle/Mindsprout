import Foundation
import SwiftData
import Testing
@testable import Mindsprout

private final class AccountDeletionTestKeychain: KeychainStoring, @unchecked Sendable {
    var storage: [String: String] = [:]
    func save(_ value: String, for key: String) { storage[key] = value }
    func read(for key: String) -> String? { storage[key] }
    func delete(for key: String) { storage[key] = nil }
}

private enum AccountDeletionMediaFailure: Error {
    case failed
}

private final class FailingDeletionMediaStore: MediaStoring {
    func url(for relativePath: String) -> URL {
        URL(fileURLWithPath: "/tmp").appendingPathComponent(relativePath)
    }

    func write(_ data: Data, kind: MediaKind, fileExtension: String) throws -> String {
        "photos/unused.\(fileExtension)"
    }

    func write(_ data: Data, relativePath: String) throws {}

    func read(relativePath: String) throws -> Data {
        Data()
    }

    func delete(relativePath: String) throws {
        throw AccountDeletionMediaFailure.failed
    }
}

@MainActor
struct AccountDeletionServiceTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "account-deletion-tests-\(UUID().uuidString)")!
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("mindsprout-account-deletion-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func deletesAllLocalAccountModels() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let defaults = makeDefaults()
        let auth = LocalAuthService()
        let mediaStore = MediaStore(root: temporaryRoot())

        context.insert(User(displayName: "Traveler"))
        context.insert(Trip(destination: "Kyoto", country: "Japan"))
        context.insert(Reflection(tripID: UUID(), text: "A quiet street"))
        context.insert(MediaAsset(kind: .photo, relativePath: "photos/moment.jpg"))
        context.insert(Sprout(name: "Miso", xp: 80, level: 3))
        try context.save()

        try AccountDeletionService(mediaStore: mediaStore, defaults: defaults, auth: auth)
            .deleteAccount(in: context)

        #expect(try context.fetch(FetchDescriptor<User>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Trip>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Reflection>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MediaAsset>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Sprout>()).isEmpty)
    }

    @Test func deletesMediaAndProfilePhotoFiles() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let mediaStore = MediaStore(root: root)
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        try mediaStore.write(Data("photo".utf8), relativePath: "photos/moment.jpg")
        try mediaStore.write(Data("audio".utf8), relativePath: "audio/moment.m4a")
        try mediaStore.write(Data("profile".utf8), relativePath: "profiles/avatar.jpg")
        context.insert(MediaAsset(kind: .photo, relativePath: "photos/moment.jpg"))
        context.insert(MediaAsset(kind: .audio, relativePath: "audio/moment.m4a"))
        context.insert(User(displayName: "Traveler", profilePhotoPath: "profiles/avatar.jpg"))
        try context.save()

        try AccountDeletionService(mediaStore: mediaStore, defaults: makeDefaults(), auth: LocalAuthService())
            .deleteAccount(in: context)

        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("photos/moment.jpg").path))
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("audio/moment.m4a").path))
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("profiles/avatar.jpg").path))
    }

    @Test func clearsAccountOwnedDefaults() throws {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "isLoggedIn")
        defaults.set(true, forKey: "hasCompletedOnboarding")
        defaults.set("Miso", forKey: "sproutName")
        defaults.set(4, forKey: "sproutLevel")
        defaults.set(2, forKey: "sproutGlassesChoice")
        defaults.set(true, forKey: "reflected_2026-07-01")
        defaults.set(Data("cached".utf8), forKey: "\(AppleAuthService.cachedProfileKeyPrefix)apple-123")
        defaults.set("keep", forKey: "unrelated")

        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        try AccountDeletionService(mediaStore: MediaStore(root: temporaryRoot()), defaults: defaults, auth: LocalAuthService())
            .deleteAccount(in: context)

        #expect(defaults.object(forKey: "isLoggedIn") == nil)
        #expect(defaults.object(forKey: "hasCompletedOnboarding") == nil)
        #expect(defaults.object(forKey: "sproutName") == nil)
        #expect(defaults.object(forKey: "sproutLevel") == nil)
        #expect(defaults.object(forKey: "sproutGlassesChoice") == nil)
        #expect(defaults.object(forKey: "reflected_2026-07-01") == nil)
        #expect(defaults.object(forKey: "\(AppleAuthService.cachedProfileKeyPrefix)apple-123") == nil)
        #expect(defaults.string(forKey: "unrelated") == "keep")
    }

    @Test func clearsAppleIdentityAndCachedProfile() throws {
        let keychain = AccountDeletionTestKeychain()
        let defaults = makeDefaults()
        let auth = AppleAuthService(keychain: keychain, defaults: defaults)
        auth.handleAuthorization(userID: "apple-123")
        auth.updateCachedProfile(for: "apple-123", displayName: "Ada", email: "ada@example.com")

        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        try AccountDeletionService(mediaStore: MediaStore(root: temporaryRoot()), defaults: defaults, auth: auth)
            .deleteAccount(in: context)

        #expect(auth.state == .localOnly)
        #expect(keychain.read(for: AppleAuthService.userIDKey) == nil)
        #expect(defaults.object(forKey: AppleAuthService.isLoggedInKey) == nil)
        #expect(auth.cachedProfile(for: "apple-123") == nil)
    }

    @Test func mediaDeletionFailurePreventsModelDefaultsAndAuthCleanup() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        let defaults = makeDefaults()
        let keychain = AccountDeletionTestKeychain()
        let auth = AppleAuthService(keychain: keychain, defaults: defaults)
        auth.handleAuthorization(userID: "apple-123")
        defaults.set(true, forKey: "hasCompletedOnboarding")

        context.insert(User(appleUserID: "apple-123", displayName: "Traveler"))
        context.insert(Trip(destination: "Kyoto", country: "Japan"))
        context.insert(Reflection(tripID: UUID(), text: "A quiet street"))
        context.insert(MediaAsset(kind: .photo, relativePath: "photos/moment.jpg"))
        context.insert(Sprout(name: "Miso", xp: 80, level: 3))
        try context.save()

        #expect(throws: AccountDeletionMediaFailure.self) {
            try AccountDeletionService(mediaStore: FailingDeletionMediaStore(), defaults: defaults, auth: auth)
                .deleteAccount(in: context)
        }

        #expect(try context.fetch(FetchDescriptor<User>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Trip>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Reflection>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<MediaAsset>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Sprout>()).count == 1)
        #expect(defaults.bool(forKey: "hasCompletedOnboarding") == true)
        #expect(auth.state == .signedIn(userID: "apple-123"))
        #expect(keychain.read(for: AppleAuthService.userIDKey) == "apple-123")
    }
}
