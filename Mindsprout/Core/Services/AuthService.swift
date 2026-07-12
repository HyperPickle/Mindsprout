import Foundation

enum AuthState: Sendable, Equatable {
    case localOnly
    case signedIn(userID: String)
}

extension AuthState {
    var userID: String? {
        guard case .signedIn(let userID) = self else { return nil }
        return userID
    }
}

struct CachedAppleProfile: Sendable, Equatable, Codable {
    var displayName: String?
    var email: String?
}

protocol AuthService: AnyObject {
    var state: AuthState { get }
    func cachedProfile(for userID: String) -> CachedAppleProfile?
    func updateCachedProfile(for userID: String, displayName: String?, email: String?)
    func handleAuthorization(userID: String)
    func signOut()
    func deleteLocalAccountIdentity()
    func revalidate() async
}

final class LocalAuthService: AuthService {
    var state: AuthState = .localOnly
    func cachedProfile(for userID: String) -> CachedAppleProfile? { nil }
    func updateCachedProfile(for userID: String, displayName: String?, email: String?) {}
    func handleAuthorization(userID: String) {}
    func signOut() {}
    func deleteLocalAccountIdentity() {
        state = .localOnly
    }
    func revalidate() async {}
}
