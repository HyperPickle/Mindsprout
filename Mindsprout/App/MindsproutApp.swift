import SwiftUI
import SwiftData

@main
struct MindsproutApp: App {
    private let modelContainer: ModelContainer
    private let appEnvironment: AppEnvironment
    
    @AppStorage("appThemePreference") private var themePreference: AppThemePreference = .system

    init() {
        FontRegistration.registerBundledFontsIfNeeded()
        let container = PersistenceController.makeContainer()
        let environment = AppEnvironment.live()
        SampleData.seedIfEmpty(context: container.mainContext, mediaStore: environment.mediaStore)
        modelContainer = container
        appEnvironment = environment
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environment(\.appEnvironment, appEnvironment)
                .preferredColorScheme(themePreference.colorScheme)
                .task { AppIconManager.apply(themePreference) }
                .onChange(of: themePreference) { _, newValue in
                    AppIconManager.apply(newValue)
                }
        }
        .modelContainer(modelContainer)
    }

    @ViewBuilder private var rootContent: some View {
        #if DEBUG
        if let screen = ProcessInfo.processInfo.environment["MS_SCREEN"] {
            ScreenshotHost(screen: screen, container: modelContainer)
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
}
