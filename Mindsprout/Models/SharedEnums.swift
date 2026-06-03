//
//  SharedEnums.swift
//  Mindsprout
//
//  Small value enums shared across the SwiftData models. String-backed and
//  Codable so SwiftData stores them as stable raw values (safe for a later
//  CloudKit migration).
//

import Foundation

/// The kind of trip, chosen at creation. Drives the expectations presets.
enum TripType: String, Codable, CaseIterable, Sendable, Identifiable {
    case solo
    case friends
    case family
    case business

    var id: String { rawValue }
}

/// Whether a reflection's body is typed text or an audio recording.
/// (Photos may be attached to either.)
enum ReflectionBodyKind: String, Codable, Sendable {
    case text
    case audio
}

/// On-disk media kind, used by `MediaAsset` and `MediaStore`.
enum MediaKind: String, Codable, Sendable {
    case photo
    case audio
}

/// The Sprout's current animation/behavior state. Drives Home art.
enum SproutState: String, Codable, CaseIterable, Sendable {
    case sleeping
    case idle
    /// A reflection is available to log today.
    case hungry
    case readyToEvolve
    case evolving
}
