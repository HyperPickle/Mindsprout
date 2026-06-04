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
