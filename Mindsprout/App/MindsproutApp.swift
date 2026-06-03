//
//  MindsproutApp.swift
//  Mindsprout
//
//  App entry point. Builds the composition root (`AppEnvironment`), attaches the
//  SwiftData model container, and shows the `RootView` shell.
//

import SwiftUI
import SwiftData

@main
struct MindsproutApp: App {
    /// The shared SwiftData container for the whole app.
    private let modelContainer: ModelContainer
    /// The composition root (services + config), injected via the environment.
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
