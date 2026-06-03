import SwiftUI

struct AppEnvironment {
    var gameConfig: GameConfig
    var ai: any AIGenerationService
    var mediaStore: any MediaStoring
    var contentPackLoader: any ContentPackProviding
    var analytics: any AnalyticsService
    var auth: any AuthService

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
    @Entry var appEnvironment: AppEnvironment = .preview

    var gameConfig: GameConfig { appEnvironment.gameConfig }
    var aiGenerationService: any AIGenerationService { appEnvironment.ai }
}
