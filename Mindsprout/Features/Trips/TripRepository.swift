import Foundation
import SwiftData

@MainActor
struct TripRepository {
    let context: ModelContext

    func allTrips() throws -> [Trip] {
        try context.fetch(FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }

    @discardableResult
    func create(
        destination: String,
        country: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        startDate: Date,
        endDate: Date,
        type: TripType,
        expectations: [String]
    ) throws -> Trip {
        let trips = try allTrips()
        let trip = Trip(
            destination: destination,
            country: country,
            latitude: latitude,
            longitude: longitude,
            startDate: startDate,
            endDate: endDate,
            type: type,
            expectations: expectations
        )
        
        // If this is the first trip, make it manually active by default
        if trips.isEmpty {
            trip.isManuallyActive = true
        }

        context.insert(trip)
        try context.save()
        return trip
    }

    func delete(_ trip: Trip) throws {
        context.delete(trip)
        try context.save()
    }

    func memoryCount(for trip: Trip) throws -> Int {
        let tripID = trip.id
        var descriptor = FetchDescriptor<Reflection>(
            predicate: #Predicate { $0.tripID == tripID && $0.isDraft == false }
        )
        descriptor.propertiesToFetch = [\.id]
        return try context.fetchCount(descriptor)
    }

    func reflections(for trip: Trip) throws -> [Reflection] {
        let tripID = trip.id
        return try context.fetch(
            FetchDescriptor<Reflection>(
                predicate: #Predicate { $0.tripID == tripID && $0.isDraft == false },
                sortBy: [SortDescriptor(\.dayIndex)]
            )
        )
    }

    func activeTrip(on date: Date = Date()) throws -> Trip? {
        TripResolver.active(in: try allTrips(), on: date)
    }
}

enum TripResolver {
    static func active(in trips: [Trip], on date: Date = Date(), calendar: Calendar = .current) -> Trip? {
        let pinned = trips.filter(\.isManuallyActive)
        if !pinned.isEmpty {
            return pinned.max { $0.createdAt < $1.createdAt }
        }
        let containing = trips.filter { $0.isActive(on: date, calendar: calendar) }
        let pool = containing.isEmpty ? trips : containing
        return pool.max { $0.createdAt < $1.createdAt }
    }

    static func partition(_ trips: [Trip], on date: Date = Date()) -> (active: Trip?, revisit: [Trip]) {
        guard let active = active(in: trips, on: date) else { return (nil, []) }
        let revisit = trips
            .filter { $0.id != active.id }
            .sorted { $0.startDate > $1.startDate }
        return (active, revisit)
    }
}
