import SwiftUI
import SwiftData

@main
struct MindsproutApp: App {
    private let modelContainer: ModelContainer
    private let appEnvironment: AppEnvironment

    init() {
        FontRegistration.registerBundledFontsIfNeeded()
        modelContainer = PersistenceController.makeContainer()
        appEnvironment = .live()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, appEnvironment)
        }
        .modelContainer(modelContainer)
    }
}
