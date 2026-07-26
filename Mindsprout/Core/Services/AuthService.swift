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

protocol AuthService: AnyObject {
    var state: AuthState { get }
    func handleAuthorization(userID: String)
    func signOut()
    func deleteLocalAccountIdentity()
    func revalidate() async
}

final class LocalAuthService: AuthService {
    var state: AuthState = .localOnly
    func handleAuthorization(userID: String) {}
    func signOut() {}
    func deleteLocalAccountIdentity() {
        state = .localOnly
    }
    func revalidate() async {}
}
