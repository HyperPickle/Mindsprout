//
//  FeatureFlags.swift
//  Mindsprout
//
//  Lightweight compile-time/launch-time flags. Kept tiny for MVP; a remote or
//  persisted flag store can replace this without changing call sites.
//

import Foundation

struct FeatureFlags: Sendable {
    /// Gates the first-launch onboarding. When false, onboarding is skipped
    /// entirely (the gate is also satisfied once completed and persisted).
    var onboardingEnabled: Bool = true

    static let `default` = FeatureFlags()
}
