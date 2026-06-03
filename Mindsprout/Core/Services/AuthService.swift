import Foundation

// Seam for Sign in with Apple / accounts. MVP is single-user, local-only.
enum AuthState: Sendable, Equatable {
    case localOnly
    case signedIn(userID: String)
}

protocol AuthService: Sendable {
    var state: AuthState { get }
}

struct LocalAuthService: AuthService {
    let state: AuthState = .localOnly
}
