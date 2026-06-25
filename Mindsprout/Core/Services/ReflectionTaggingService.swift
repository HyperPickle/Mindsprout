import Foundation

struct ReflectionTaggingInput: Sendable, Equatable {
    var text: String?
    var bodyKind: ReflectionBodyKind
    var audioDurationSeconds: Double?
    var photoCount: Int
    var promptText: String
}

enum ReflectionTag: String, CaseIterable, Sendable {
    case insightful = "Insightful"
    case thoughtful = "Thoughtful"
    case vivid = "Vivid"
    case honest = "Honest"
    case curious = "Curious"
    case grateful = "Grateful"
    case present = "Present"
    case expressive = "Expressive"

    var label: String {
        switch self {
        case .insightful:
            String(localized: "Insightful")
        case .thoughtful:
            String(localized: "Thoughtful")
        case .vivid:
            String(localized: "Vivid")
        case .honest:
            String(localized: "Honest")
        case .curious:
            String(localized: "Curious")
        case .grateful:
            String(localized: "Grateful")
        case .present:
            String(localized: "Present")
        case .expressive:
            String(localized: "Expressive")
        }
    }
}

struct ReflectionTaggingService: Sendable {
    func tag(for input: ReflectionTaggingInput) -> ReflectionTag {
        let text = [input.text, input.promptText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let normalized = text.lowercased()
        let words = Self.words(in: normalized)
        let wordSet = Set(words)
        let wordCount = words.count
        let sentenceCount = normalized.filter { ".!?".contains($0) }.count

        var scores = Dictionary(uniqueKeysWithValues: ReflectionTag.allCases.map { ($0, 0) })

        scores[.insightful, default: 0] += Self.keywordScore(
            in: normalized,
            words: wordSet,
            phrases: ["realized", "learned", "noticed", "understood", "discovered"],
            points: 4
        )

        if wordCount >= 40 {
            scores[.thoughtful, default: 0] += 3
        } else if wordCount >= 20 {
            scores[.thoughtful, default: 0] += 2
        }
        if sentenceCount >= 2 {
            scores[.thoughtful, default: 0] += 2
        }
        scores[.thoughtful, default: 0] += Self.keywordScore(
            in: normalized,
            words: wordSet,
            phrases: ["because", "why", "how"],
            points: 3
        )

        let sensoryHits = Self.keywordHitCount(
            in: normalized,
            words: wordSet,
            phrases: ["warm", "bright", "quiet", "loud", "smelled", "smell", "soft", "cold", "golden", "color", "colour"]
        )
        if input.photoCount > 0 {
            scores[.vivid, default: 0] += 2
        }
        if sensoryHits > 0 {
            scores[.vivid, default: 0] += min(4, sensoryHits * 2)
        }
        if input.photoCount > 0 && sensoryHits > 0 {
            scores[.vivid, default: 0] += 2
        }

        scores[.honest, default: 0] += Self.keywordScore(
            in: normalized,
            words: wordSet,
            phrases: ["i felt", "i was", "i struggled", "i missed", "felt nervous", "felt relieved", "felt moved"],
            points: 4
        )

        if normalized.contains("?") {
            scores[.curious, default: 0] += 4
        }
        scores[.curious, default: 0] += Self.keywordScore(
            in: normalized,
            words: wordSet,
            phrases: ["wonder", "wondered", "maybe", "not sure"],
            points: 4
        )

        scores[.grateful, default: 0] += Self.keywordScore(
            in: normalized,
            words: wordSet,
            phrases: ["grateful", "thankful", "appreciated", "lucky"],
            points: 5
        )

        scores[.present, default: 0] += Self.keywordScore(
            in: normalized,
            words: wordSet,
            phrases: ["today", "this morning", "right now", "here", "now"],
            points: 3
        )

        if input.bodyKind == .audio {
            scores[.expressive, default: 0] += 3
        }
        if (input.audioDurationSeconds ?? 0) >= 30 {
            scores[.expressive, default: 0] += 2
        }
        let emotionHits = Self.keywordHitCount(
            in: normalized,
            words: wordSet,
            phrases: ["felt", "moved", "relieved", "joy", "happy", "tender", "overwhelmed", "missed", "struggled"]
        )
        if emotionHits >= 2 {
            scores[.expressive, default: 0] += 2
        }

        let best = ReflectionTag.allCases.reduce(ReflectionTag.insightful) { currentBest, candidate in
            scores[candidate, default: 0] > scores[currentBest, default: 0] ? candidate : currentBest
        }

        guard scores[best, default: 0] >= 3 else {
            return wordCount <= 8 ? .present : .thoughtful
        }

        return best
    }

    func label(for input: ReflectionTaggingInput) -> String {
        tag(for: input).label
    }

    private static func words(in text: String) -> [String] {
        text.split { !$0.isLetter && !$0.isNumber && $0 != "'" }
            .map(String.init)
    }

    private static func keywordScore(
        in text: String,
        words: Set<String>,
        phrases: [String],
        points: Int
    ) -> Int {
        keywordHitCount(in: text, words: words, phrases: phrases) * points
    }

    private static func keywordHitCount(
        in text: String,
        words: Set<String>,
        phrases: [String]
    ) -> Int {
        phrases.reduce(into: 0) { count, phrase in
            if phrase.contains(" ") {
                if text.contains(phrase) {
                    count += 1
                }
            } else if words.contains(phrase) {
                count += 1
            }
        }
    }
}
