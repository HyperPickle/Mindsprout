//
//  AIGenerationService.swift
//  Mindsprout
//
//  The seam for all AI-derived content (trip theme, headline memory, mood tags,
//  growth insight, postcard). The core loop is offline; this protocol is the
//  ONLY place a real LLM (Claude via a future backend proxy) would plug in —
//  no feature-code changes. The shipped default is a deterministic on-device
//  template generator (`TemplateAIGenerationService`).
//
//  Methods are `async` so a networked implementation slots in unchanged; the
//  template impl simply returns synchronously-computed values.
//
//  ── LLM seam (documented, not built — Plan §5.2) ───────────────────────────
//  A real implementation would:
//    • build a prompt from the request value,
//    • POST it to a backend proxy that calls Claude (keys never on-device),
//    • map the response back into the same return types below,
//    • degrade to the template result on failure/offline.
//  Selection happens at composition root (AppEnvironment); callers stay agnostic.
//

import Foundation

// MARK: - Request value types

/// Context for generating a trip's theme.
struct TripThemeRequest: Sendable {
    var tripType: TripType
    var destination: String
    var country: String
    var expectations: [String]
}

/// Context derived from a single committed reflection.
struct ReflectionContext: Sendable {
    var tripType: TripType
    var destination: String
    var highlightPrompt: String
    var text: String?
    var hasPhoto: Bool
    var hasAudio: Bool
}

// MARK: - Response value types

/// A short growth insight surfaced in the level-up flow.
struct GrowthInsight: Sendable, Equatable {
    /// Single trait word, e.g. "Courage".
    var trait: String
    /// One-line supporting blurb.
    var blurb: String
}

/// A narrative postcard summarizing a milestone.
struct Postcard: Sendable, Equatable {
    var title: String
    var body: String
}

// MARK: - Protocol

protocol AIGenerationService: Sendable {
    /// A short evocative theme for a trip (e.g. "Wonder came slowly").
    func generateTripTheme(_ request: TripThemeRequest) async -> String
    /// A headline memory for a trip, given recent reflection text (most recent first).
    /// Falls back to the most recent text when nothing better can be derived.
    func generateHeadline(recentReflectionTexts: [String]) async -> String
    /// Mood tags for a reflection (e.g. ["Serenity", "Curiosity"]).
    func generateMoodTags(_ context: ReflectionContext) async -> [String]
    /// A growth insight (trait word + blurb) for a level-up.
    func generateGrowthInsight(_ context: ReflectionContext) async -> GrowthInsight
    /// A narrative postcard for a milestone.
    func generatePostcard(_ context: ReflectionContext) async -> Postcard
}
