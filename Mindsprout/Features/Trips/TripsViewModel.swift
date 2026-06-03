import Foundation
import SwiftData

struct TripSummary: Identifiable {
    let trip: Trip
    let memoryCount: Int
    let coverAssetID: UUID?
    let photoStripIDs: [UUID]
    var id: UUID { trip.id }
}

@MainActor
@Observable
final class TripsViewModel {
    private(set) var active: TripSummary?
    private(set) var revisit: [TripSummary] = []
    var isEmpty: Bool { active == nil && revisit.isEmpty }

    func load(context: ModelContext, now: Date = Date()) {
        let repo = TripRepository(context: context)
        guard let trips = try? repo.allTrips() else { return }
        let (activeTrip, revisitTrips) = TripResolver.partition(trips, on: now)
        active = activeTrip.map { summarize($0, repo: repo) }
        revisit = revisitTrips.map { summarize($0, repo: repo) }
    }

    private func summarize(_ trip: Trip, repo: TripRepository) -> TripSummary {
        let reflections = (try? repo.reflections(for: trip)) ?? []
        let strip = reflections.flatMap(\.photoAssetIDs)
        return TripSummary(
            trip: trip,
            memoryCount: (try? repo.memoryCount(for: trip)) ?? reflections.count,
            coverAssetID: trip.coverAssetID ?? strip.first,
            photoStripIDs: Array(strip.prefix(3))
        )
    }
}
