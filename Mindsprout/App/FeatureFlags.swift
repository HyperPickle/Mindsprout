import Foundation

struct FeatureFlags: Sendable {
    var onboardingEnabled: Bool = true

    static let `default` = FeatureFlags()
}
