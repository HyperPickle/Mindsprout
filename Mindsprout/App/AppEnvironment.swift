//
//  AppEnvironment.swift
//  Mindsprout
//
//  Composition root. Bundles the app's services/config and injects them through
//  the SwiftUI environment. Swapping an implementation (e.g. a networked
//  `AIGenerationService`, a real `AnalyticsService`) happens here only —
//  feature code reads from the environment and stays agnostic.
//

import SwiftUI

struct AppEnvironment {
    var gameConfig: GameConfig
    var ai: any AIGenerationService
    var mediaStore: any MediaStoring
    var contentPackLoader: any ContentPackProviding
    var analytics: any AnalyticsService
    var auth: any AuthService

    /// The shipped configuration: placeholder economy + deterministic template
    /// AI + on-device file media store. Fully offline.
    static func live() -> AppEnvironment {
        AppEnvironment(
            gameConfig: .default,
            ai: TemplateAIGenerationService(),
            mediaStore: MediaStore(),
            contentPackLoader: ContentPackLoader(),
            analytics: NoOpAnalyticsService(),
            auth: LocalAuthService()
        )
    }

    /// Lightweight environment for previews (temp media root, no Documents I/O).
    static var preview: AppEnvironment {
        AppEnvironment(
            gameConfig: .default,
            ai: TemplateAIGenerationService(),
            mediaStore: MediaStore(root: FileManager.default.temporaryDirectory
                .appendingPathComponent("mindsprout-preview-media", isDirectory: true)),
            contentPackLoader: ContentPackLoader(),
            analytics: NoOpAnalyticsService(),
            auth: LocalAuthService()
        )
    }
}

extension EnvironmentValues {
    /// The composition-root services/config bundle.
    @Entry var appEnvironment: AppEnvironment = .preview
}

extension EnvironmentValues {
    /// Convenience read-only access to the economy config.
    var gameConfig: GameConfig { appEnvironment.gameConfig }
    /// Convenience read-only access to the AI generation seam.
    var aiGenerationService: any AIGenerationService { appEnvironment.ai }
}
