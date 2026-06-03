import Foundation

enum TripType: String, Codable, CaseIterable, Sendable, Identifiable {
    case solo
    case friends
    case family
    case business

    var id: String { rawValue }
}

enum ReflectionBodyKind: String, Codable, Sendable {
    case text
    case audio
}

enum MediaKind: String, Codable, Sendable {
    case photo
    case audio
}

enum SproutState: String, Codable, CaseIterable, Sendable {
    case sleeping
    case idle
    case hungry
    case readyToEvolve
    case evolving
}
