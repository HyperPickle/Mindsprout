//
//  PersistenceController.swift
//  Mindsprout
//
//  Builds the SwiftData `ModelContainer`. Local-only for MVP but deliberately
//  sync-ready: the schema uses defaulted, non-unique properties so a CloudKit
//  configuration can be added here later without a breaking migration.
//

import Foundation
import SwiftData

enum PersistenceController {
    /// Every `@Model` type in the app. Keep this list authoritative.
    static let schema = Schema([
        Trip.self,
        Reflection.self,
        MediaAsset.self,
        Sprout.self
    ])

    /// The app's on-disk container.
    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A failure here means the local store is unreadable/incompatible.
            // For MVP we fail fast; a migration/recovery path is future work.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// An ephemeral in-memory container for previews and unit tests.
    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
