import Foundation

struct PromptPack: Codable, Sendable, Equatable {
    var highlightPrompts: [String: [String]]
    var inspirationPrompts: [String]

    func highlights(for type: TripType) -> [String] {
        highlightPrompts[type.rawValue] ?? highlightPrompts["default"] ?? []
    }
}

struct ExpectationPack: Codable, Sendable, Equatable {
    var presets: [String: [String]]

    func presets(for type: TripType) -> [String] {
        presets[type.rawValue] ?? []
    }
}

struct ContentPack: Sendable, Equatable {
    var prompts: PromptPack
    var expectations: ExpectationPack
}
