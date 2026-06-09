import Foundation

enum AuthState: Sendable, Equatable {
    case localOnly
    case signedIn(userID: String)
}

protocol AuthService: AnyObject {
    var state: AuthState { get }
    func handleAuthorization(userID: String)
    func signOut()
    func revalidate() async
}

final class LocalAuthService: AuthService {
    var state: AuthState = .localOnly
    func handleAuthorization(userID: String) {}
    func signOut() {}
    func revalidate() async {}
}
