import Foundation
import AuthenticationServices

@Observable
final class AppleAuthService: AuthService {
    static let userIDKey = "apple_user_id"
    static let isLoggedInKey = "isLoggedIn"
    static let cachedProfileKeyPrefix = "apple_profile_"

    private let keychain: any KeychainStoring
    private let defaults: UserDefaults

    private(set) var state: AuthState

    init(keychain: any KeychainStoring = KeychainStore(), defaults: UserDefaults = .standard) {
        self.keychain = keychain
        self.defaults = defaults
        if let userID = keychain.read(for: Self.userIDKey) {
            state = .signedIn(userID: userID)
        } else {
            state = .localOnly
        }
    }

    func cachedProfile(for userID: String) -> CachedAppleProfile? {
        guard let data = defaults.data(forKey: profileKey(for: userID)) else { return nil }
        return try? JSONDecoder().decode(CachedAppleProfile.self, from: data)
    }

    func updateCachedProfile(for userID: String, displayName: String?, email: String?) {
        let existing = cachedProfile(for: userID)
        let mergedProfile = CachedAppleProfile(
            displayName: nonEmpty(displayName) ?? existing?.displayName,
            email: nonEmpty(email) ?? existing?.email
        )
        guard mergedProfile.displayName != nil || mergedProfile.email != nil else { return }
        guard let data = try? JSONEncoder().encode(mergedProfile) else { return }
        defaults.set(data, forKey: profileKey(for: userID))
    }

    func handleAuthorization(userID: String) {
        keychain.save(userID, for: Self.userIDKey)
        state = .signedIn(userID: userID)
        defaults.set(true, forKey: Self.isLoggedInKey)
    }

    func signOut() {
        keychain.delete(for: Self.userIDKey)
        state = .localOnly
        defaults.set(false, forKey: Self.isLoggedInKey)
    }

    func deleteLocalAccountIdentity() {
        if let userID = keychain.read(for: Self.userIDKey) {
            defaults.removeObject(forKey: profileKey(for: userID))
        }
        keychain.delete(for: Self.userIDKey)
        defaults.removeObject(forKey: Self.isLoggedInKey)
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(Self.cachedProfileKeyPrefix) }
            .forEach { defaults.removeObject(forKey: $0) }
        state = .localOnly
    }

    func revalidate() async {
        guard case .signedIn(let userID) = state else { return }
        let provider = ASAuthorizationAppleIDProvider()
        let credentialState: ASAuthorizationAppleIDProvider.CredentialState =
            await withCheckedContinuation { continuation in
                provider.getCredentialState(forUserID: userID) { credentialState, _ in
                    continuation.resume(returning: credentialState)
                }
            }
        if credentialState == .revoked || credentialState == .notFound {
            signOut()
        }
    }

    private func profileKey(for userID: String) -> String {
        "\(Self.cachedProfileKeyPrefix)\(userID)"
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
