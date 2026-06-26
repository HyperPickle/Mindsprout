import Testing
import Foundation
import SwiftData
@testable import Mindsprout

@MainActor
struct PersistenceTests {

    @Test func insertsAndFetchesTrip() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        let trip = Trip(destination: "Kyoto", country: "Japan", type: .solo)
        context.insert(trip)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Trip>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.destination == "Kyoto")
        #expect(fetched.first?.country == "Japan")
        #expect(fetched.first?.type == .solo)
    }

    @Test func schemaContainsAllModels() {
        // All four Phase 0 models are registered in the container schema.
        let names = Set(PersistenceController.schema.entities.map(\.name))
        #expect(names.isSuperset(of: ["Trip", "Reflection", "MediaAsset", "Sprout"]))
    }

    @Test func migrationPlanReferencesBaselineSchema() {
        // The migration plan's first (baseline) version must list the same models
        // as the registered schema — guards against drift.
        #expect(MindsproutMigrationPlan.schemas.count == 1)
        let planModels = Set(MindsproutSchemaV1.models.map { String(describing: $0) })
        #expect(planModels == ["Trip", "Reflection", "MediaAsset", "Sprout", "User"])
    }

    @Test func containerBuildsFromVersionedPlanAndAllModelsQueryable() throws {
        // Build a real (in-memory) container and confirm every model is queryable
        // through it, exercising the versioned-schema model list end to end.
        let container = try ModelContainer(
            for: PersistenceController.schema,
            migrationPlan: MindsproutMigrationPlan.self,
            configurations: [ModelConfiguration(schema: PersistenceController.schema, isStoredInMemoryOnly: true)]
        )
        let context = ModelContext(container)

        #expect(try context.fetch(FetchDescriptor<Trip>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Reflection>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MediaAsset>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Sprout>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<User>()).isEmpty)
    }

    @Test func tripActiveResolutionByDateRange() {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!

        let active = Trip(startDate: yesterday, endDate: tomorrow)
        #expect(active.isActive(on: now))

        let past = Trip(
            startDate: calendar.date(byAdding: .day, value: -10, to: now)!,
            endDate: calendar.date(byAdding: .day, value: -5, to: now)!
        )
        #expect(!past.isActive(on: now))
    }
}
