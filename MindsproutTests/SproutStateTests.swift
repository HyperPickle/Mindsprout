import Testing
import SwiftData
@testable import Mindsprout

struct SproutStateTests {
    @Test func sleepingMapsToIdleOnHome() {
        #expect(SproutState.sleeping.homeDisplayState == .idle)
    }

    @Test func nonSleepingStatesPassThroughOnHome() {
        for state in SproutState.allCases where state != .sleeping {
            #expect(state.homeDisplayState == state)
        }
    }

    @Test func fetchOrCreateMakesExactlyOneAndIsIdempotent() throws {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())

        let first = Sprout.fetchOrCreate(name: "Fern", in: context)
        let second = Sprout.fetchOrCreate(in: context)

        #expect(first.id == second.id)
        let all = try context.fetch(FetchDescriptor<Sprout>())
        #expect(all.count == 1)
    }

    @Test func fetchOrCreateSeedsNameOnlyWhenExistingNameIsEmpty() {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())

        // First creation seeds the name.
        let created = Sprout.fetchOrCreate(name: "Fern", in: context)
        #expect(created.name == "Fern")

        // A later call with a different name must not overwrite a non-empty name.
        let again = Sprout.fetchOrCreate(name: "Sprout", in: context)
        #expect(again.name == "Fern")
    }

    @Test func fetchOrCreateBackfillsNameWhenExistingNameIsEmpty() {
        let context = ModelContext(PersistenceController.makeInMemoryContainer())

        // Created without a name (e.g. the HomeTab bootstrap path).
        let blank = Sprout.fetchOrCreate(in: context)
        #expect(blank.name.isEmpty)

        // Onboarding later supplies the name; the empty name is filled in.
        let named = Sprout.fetchOrCreate(name: "Fern", in: context)
        #expect(named.id == blank.id)
        #expect(named.name == "Fern")
    }
}
