//
//  AuthService.swift
//  Mindsprout
//
//  DOCUMENTED SEAM — unimplemented for MVP (Plan §2: "Local single-user, no
//  auth"). The app is single-user with all data on-device. This seam exists so
//  Sign in with Apple + accounts (needed when sync / Shop purchases arrive) can
//  be added later without reworking feature code.
//

import Foundation

/// The current account context. MVP is always `.localOnly`.
enum AuthState: Sendable, Equatable {
    /// No account; a single local user owns all on-device data.
    case localOnly
    /// Signed in with a stable account identifier (future).
    case signedIn(userID: String)
}

protocol AuthService: Sendable {
    var state: AuthState { get }
}

/// Default MVP implementation: always local, no accounts.
struct LocalAuthService: AuthService {
    let state: AuthState = .localOnly
}
