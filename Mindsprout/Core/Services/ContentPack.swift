import Foundation

struct HighlightPrompt: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var title: String
    var subtitle: String
}

struct PromptPack: Codable, Sendable, Equatable {
    var highlightPrompts: [String: [HighlightPrompt]]
    var inspirationPrompts: [String]

    func highlights(for type: TripType) -> [HighlightPrompt] {
        let defaults = highlightPrompts["default"] ?? []
        let specific = highlightPrompts[type.rawValue] ?? []
        return defaults + specific
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
