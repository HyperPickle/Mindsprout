import Foundation
import AuthenticationServices

@Observable
final class AppleAuthService: AuthService {
    static let userIDKey = "apple_user_id"
    static let isLoggedInKey = "isLoggedIn"

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
}
