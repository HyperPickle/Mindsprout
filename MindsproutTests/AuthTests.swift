import Testing
import Foundation
import SwiftData
@testable import Mindsprout

private final class InMemoryKeychain: KeychainStoring, @unchecked Sendable {
    var storage: [String: String] = [:]
    func save(_ value: String, for key: String) { storage[key] = value }
    func read(for key: String) -> String? { storage[key] }
    func delete(for key: String) { storage[key] = nil }
}

@MainActor
struct AuthTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "auth-tests-\(UUID().uuidString)")!
    }

    @Test func handleAuthorizationSignsInAndPersists() {
        let keychain = InMemoryKeychain()
        let defaults = makeDefaults()
        let service = AppleAuthService(keychain: keychain, defaults: defaults)

        service.handleAuthorization(userID: "apple-123")

        #expect(service.state == .signedIn(userID: "apple-123"))
        #expect(keychain.read(for: AppleAuthService.userIDKey) == "apple-123")
        #expect(defaults.object(forKey: AppleAuthService.isLoggedInKey) == nil)
    }

    @Test func signOutClearsState() {
        let keychain = InMemoryKeychain()
        let defaults = makeDefaults()
        let service = AppleAuthService(keychain: keychain, defaults: defaults)
        service.handleAuthorization(userID: "apple-123")

        service.signOut()

        #expect(service.state == .localOnly)
        #expect(keychain.read(for: AppleAuthService.userIDKey) == nil)
        #expect(defaults.object(forKey: AppleAuthService.isLoggedInKey) == nil)
    }

    @Test func initPurgesLegacyAppleProfileAndLoginDefaults() {
        let keychain = InMemoryKeychain()
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppleAuthService.isLoggedInKey)
        defaults.set(Data("legacy".utf8), forKey: "\(AppleAuthService.cachedProfileKeyPrefix)apple-123")

        let service = AppleAuthService(keychain: keychain, defaults: defaults)

        #expect(service.state == .localOnly)
        #expect(defaults.object(forKey: AppleAuthService.isLoggedInKey) == nil)
        #expect(defaults.object(forKey: "\(AppleAuthService.cachedProfileKeyPrefix)apple-123") == nil)
    }

    @Test func initRestoresSignedInStateFromKeychain() {
        let keychain = InMemoryKeychain()
        keychain.save("apple-999", for: AppleAuthService.userIDKey)

        let service = AppleAuthService(keychain: keychain, defaults: makeDefaults())

        #expect(service.state == .signedIn(userID: "apple-999"))
    }

    @Test func upsertInsertsNewUser() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        User.upsert(appleUserID: "u1", displayName: "Ada Lovelace", in: context)

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        #expect(users.first?.displayName == "Ada Lovelace")
        #expect(users.first?.email.isEmpty == true)
    }

    @Test func upsertPreservesNameWhenSubsequentSignInOmitsIt() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        User.upsert(appleUserID: "u1", displayName: "Ada Lovelace", in: context)
        User.upsert(appleUserID: "u1", displayName: nil, in: context)

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        #expect(users.first?.displayName == "Ada Lovelace")
    }

    @Test func fetchOrCreateLocalReusesTheLocalSwiftDataUser() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        let first = User.fetchOrCreateLocal(in: context)
        first.displayName = "Local Traveler"
        try context.save()
        let second = User.fetchOrCreateLocal(in: context)

        #expect(try context.fetch(FetchDescriptor<User>()).count == 1)
        #expect(first.persistentModelID == second.persistentModelID)
        #expect(second.displayName == "Local Traveler")
    }

    @Test func currentUserPrefersSignedInAppleUserID() {
        let first = User(appleUserID: "u1", displayName: "First")
        let second = User(appleUserID: "u2", displayName: "Second")

        let current = User.current(in: [first, second], userID: "u2")

        #expect(current?.appleUserID == "u2")
        #expect(current?.displayName == "Second")
    }

    @Test func currentUserPrefersLocalUserWithoutAuthentication() {
        let apple = User(appleUserID: "u1", displayName: "Apple")
        let local = User(displayName: "Local")

        let current = User.current(in: [apple, local], userID: nil)

        #expect(current?.appleUserID.isEmpty == true)
        #expect(current?.displayName == "Local")
    }

    @Test func removeLegacyEmailsClearsExistingSwiftDataValues() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        context.insert(User(displayName: "Traveler", email: "legacy@example.com"))
        try context.save()

        User.removeLegacyEmails(in: context)

        #expect(try context.fetch(FetchDescriptor<User>()).first?.email.isEmpty == true)
    }
}
