import Foundation
import AuthenticationServices

@Observable
final class AppleAuthService: AuthService {
    static let userIDKey = "apple_user_id"
    /// Retained only so upgrades and account deletion can remove old auth state.
    static let isLoggedInKey = "isLoggedIn"
    /// Retained only to purge pre-1.0 cached names and email addresses.
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
        purgeLegacyProfileCache()
        defaults.removeObject(forKey: Self.isLoggedInKey)
    }

    func handleAuthorization(userID: String) {
        keychain.save(userID, for: Self.userIDKey)
        state = .signedIn(userID: userID)
    }

    func signOut() {
        keychain.delete(for: Self.userIDKey)
        state = .localOnly
        defaults.removeObject(forKey: Self.isLoggedInKey)
    }

    func deleteLocalAccountIdentity() {
        keychain.delete(for: Self.userIDKey)
        defaults.removeObject(forKey: Self.isLoggedInKey)
        purgeLegacyProfileCache()
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

    private func purgeLegacyProfileCache() {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(Self.cachedProfileKeyPrefix) }
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
