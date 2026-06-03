//
//  ContentPack.swift
//  Mindsprout
//
//  Externalized, bundled curated copy (prompts + expectation presets) so the
//  core loop is fully offline and copy is editable without code. Keyed by trip
//  type/context. Loaded by `ContentPackLoader`.
//

import Foundation

/// Highlight + inspiration prompts shown during reflection capture.
struct PromptPack: Codable, Sendable, Equatable {
    /// Highlight prompts keyed by context. Always includes a `"default"` list;
    /// trip-type keys (`solo`, `friends`, …) override/augment it.
    var highlightPrompts: [String: [String]]
    /// Inspiration prompts shown in the Type entry screen.
    var inspirationPrompts: [String]

    /// Highlight prompts for a trip type, falling back to `default`.
    func highlights(for type: TripType) -> [String] {
        highlightPrompts[type.rawValue] ?? highlightPrompts["default"] ?? []
    }
}

/// Expectation presets offered per trip type in the New Trip flow.
struct ExpectationPack: Codable, Sendable, Equatable {
    /// Preset expectation strings keyed by `TripType.rawValue`.
    var presets: [String: [String]]

    func presets(for type: TripType) -> [String] {
        presets[type.rawValue] ?? []
    }
}

/// The full bundled content pack.
struct ContentPack: Sendable, Equatable {
    var prompts: PromptPack
    var expectations: ExpectationPack
}
