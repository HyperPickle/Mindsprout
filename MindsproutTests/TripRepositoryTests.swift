import Testing
import Foundation
import SwiftData
@testable import Mindsprout

@MainActor
struct TripRepositoryTests {

    private func makeRepo() -> (TripRepository, ModelContext) {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)
        return (TripRepository(context: context), context)
    }

    private func days(_ offset: Int, from date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: date)!
    }

    @Test func createPersistsTrip() throws {
        let (repo, _) = makeRepo()
        let trip = try repo.create(
            destination: "Lisbon", country: "Portugal",
            startDate: days(-1), endDate: days(2),
            type: .solo, expectations: ["Get lost on purpose"]
        )
        #expect(trip.destination == "Lisbon")
        #expect(try repo.allTrips().count == 1)
    }

    @Test func deleteRemovesTrip() throws {
        let (repo, _) = makeRepo()
        let trip = try repo.create(
            destination: "Oslo", country: "Norway",
            startDate: days(-1), endDate: days(1), type: .business, expectations: []
        )
        try repo.delete(trip)
        #expect(try repo.allTrips().isEmpty)
    }

    @Test func memoryCountCountsOnlyCommittedReflections() throws {
        let (repo, context) = makeRepo()
        let trip = try repo.create(
            destination: "Kyoto", country: "Japan",
            startDate: days(-2), endDate: days(2), type: .solo, expectations: []
        )
        context.insert(Reflection(tripID: trip.id, isDraft: false))
        context.insert(Reflection(tripID: trip.id, isDraft: false))
        context.insert(Reflection(tripID: trip.id, isDraft: true)) // draft excluded
        context.insert(Reflection(tripID: UUID(), isDraft: false))  // other trip
        try context.save()
        #expect(try repo.memoryCount(for: trip) == 2)
    }

    @Test func activeTripPrefersDateRangeContainingToday() {
        let past = Trip(startDate: days(-10), endDate: days(-5), createdAt: days(-1))
        let current = Trip(startDate: days(-1), endDate: days(1), createdAt: days(-9))
        let resolved = TripResolver.active(in: [past, current])
        #expect(resolved === current)
    }

    @Test func activeTripFallsBackToMostRecentlyCreated() {
        let older = Trip(startDate: days(-20), endDate: days(-15), createdAt: days(-10))
        let newer = Trip(startDate: days(-8), endDate: days(-4), createdAt: days(-2))
        let resolved = TripResolver.active(in: [older, newer])
        #expect(resolved === newer)
    }

    @Test func activeTripNilWhenNoTrips() {
        #expect(TripResolver.active(in: []) == nil)
    }

    @Test func partitionPutsActiveApartAndSortsRevisitByStartDate() {
        let active = Trip(destination: "Kyoto", startDate: days(-100), endDate: days(-90), createdAt: days(-1))
        let recentTravel = Trip(destination: "Tasmania", startDate: days(-30), endDate: days(-25), createdAt: days(-20))
        let olderTravel = Trip(destination: "Seoul", startDate: days(-60), endDate: days(-55), createdAt: days(-40))
        let (resolvedActive, revisit) = TripResolver.partition([recentTravel, active, olderTravel])
        #expect(resolvedActive === active)
        #expect(revisit.map(\.destination) == ["Tasmania", "Seoul"])
    }
}
