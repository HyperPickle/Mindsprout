import SwiftUI
import SwiftData

@main
struct MindsproutApp: App {
    private let modelContainer: ModelContainer
    private let appEnvironment: AppEnvironment

    init() {
        FontRegistration.registerBundledFontsIfNeeded()
        let container = PersistenceController.makeContainer()
        let environment = AppEnvironment.live()
        SampleData.seedIfEmpty(context: container.mainContext, mediaStore: environment.mediaStore)
        modelContainer = container
        appEnvironment = environment
        
        // TEMPORARY - DELETE AFTER TESTING ⚠️
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environment(\.appEnvironment, appEnvironment)
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
