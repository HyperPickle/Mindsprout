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
        #expect(defaults.bool(forKey: AppleAuthService.isLoggedInKey) == true)
    }

    @Test func signOutClearsState() {
        let keychain = InMemoryKeychain()
        let defaults = makeDefaults()
        let service = AppleAuthService(keychain: keychain, defaults: defaults)
        service.handleAuthorization(userID: "apple-123")

        service.signOut()

        #expect(service.state == .localOnly)
        #expect(keychain.read(for: AppleAuthService.userIDKey) == nil)
        #expect(defaults.bool(forKey: AppleAuthService.isLoggedInKey) == false)
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

        User.upsert(appleUserID: "u1", displayName: "Ada Lovelace", email: "ada@example.com", in: context)

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        #expect(users.first?.displayName == "Ada Lovelace")
        #expect(users.first?.email == "ada@example.com")
    }

    @Test func upsertPreservesNameWhenSubsequentSignInOmitsIt() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        User.upsert(appleUserID: "u1", displayName: "Ada Lovelace", email: "ada@example.com", in: context)
        // Apple returns name/email only on first authorization; subsequent sign-ins pass nil.
        User.upsert(appleUserID: "u1", displayName: nil, email: nil, in: context)

        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
        #expect(users.first?.displayName == "Ada Lovelace")
        #expect(users.first?.email == "ada@example.com")
    }

    @Test func cachedProfilePersistsAcrossSubsequentAuthorizations() {
        let service = AppleAuthService(keychain: InMemoryKeychain(), defaults: makeDefaults())

        service.updateCachedProfile(for: "u1", displayName: "Ada Lovelace", email: "ada@example.com")
        service.updateCachedProfile(for: "u1", displayName: nil, email: nil)

        #expect(service.cachedProfile(for: "u1")?.displayName == "Ada Lovelace")
        #expect(service.cachedProfile(for: "u1")?.email == "ada@example.com")
    }

    @Test func currentUserPrefersSignedInAppleUserID() {
        let first = User(appleUserID: "u1", displayName: "First")
        let second = User(appleUserID: "u2", displayName: "Second")

        let current = User.current(in: [first, second], userID: "u2")

        #expect(current?.appleUserID == "u2")
        #expect(current?.displayName == "Second")
    }
}
