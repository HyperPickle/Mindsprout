import Foundation
import OSLog
import SwiftData

/// Baseline schema version. Future non-additive changes add a `MindsproutSchemaV2`
/// (etc.) and a corresponding migration stage in `MindsproutMigrationPlan`.
enum MindsproutSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Trip.self, Reflection.self, MediaAsset.self, Sprout.self, User.self]
    }
}

/// Ordered list of schema versions and the migration stages between them. The
/// scaffolding is in place now; actual future migrations append a stage here.
enum MindsproutMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [MindsproutSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

enum PersistenceController {
    /// Single source of truth for the registered model list — derived from the
    /// current schema version so the container and the migration plan can't drift.
    static let schema = Schema(versionedSchema: MindsproutSchemaV1.self)

    private static let logger = Logger(subsystem: "Mindsprout", category: "Persistence")

    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: MindsproutMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            logger.error("Failed to create ModelContainer, attempting recovery: \(error, privacy: .public)")
            #if DEBUG
            fatalError("Failed to create ModelContainer: \(error)")
            #else
            return recoverWithFreshStore(configuration: configuration, originalError: error)
            #endif
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Failure here is a test/preview setup bug, not a recoverable user state.
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    /// Last-resort recovery for release builds: a corrupt or unmigratable on-disk
    /// store would otherwise hard-crash on launch. Delete the store files and
    /// rebuild empty so the app stays usable rather than bricking.
    private static func recoverWithFreshStore(
        configuration: ModelConfiguration,
        originalError: Error
    ) -> ModelContainer {
        if let url = configuration.url as URL? {
            removeStoreFiles(at: url)
        }
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: MindsproutMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            logger.fault("Recovery with fresh store failed: \(error, privacy: .public)")
            fatalError("Failed to create ModelContainer after recovery: \(originalError); recovery error: \(error)")
        }
    }

    private static func removeStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        // SwiftData/SQLite keeps WAL sidecar files alongside the main store,
        // named `<store>-wal` and `<store>-shm` (hyphen suffix, not an extension).
        let directory = url.deletingLastPathComponent()
        let name = url.lastPathComponent
        let candidates = [
            url,
            directory.appendingPathComponent(name + "-shm"),
            directory.appendingPathComponent(name + "-wal")
        ]
        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            try? fileManager.removeItem(at: candidate)
        }
    }
}
