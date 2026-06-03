//
//  Trip.swift
//  Mindsprout
//
//  Skeletal Phase 0 stub. Reflections attach to a trip by `id` (see
//  `Reflection.tripID`) rather than via a SwiftData relationship for now,
//  keeping the model decoupled and CloudKit-friendly. Finalized in Phase 1.
//
//  CloudKit-readiness: every stored property has a default value and there are
//  no unique constraints, so a `.cloudKit` model configuration can be layered
//  on later without a migration that breaks sync.
//

import Foundation
import SwiftData

@Model
final class Trip {
    /// Stable identifier; referenced by `Reflection.tripID` and cover assets.
    var id: UUID = UUID()

    /// Destination city.
    var destination: String = ""
    var country: String = ""

    var startDate: Date = Date()
    var endDate: Date = Date()

    var type: TripType = TripType.solo

    /// Multi-select presets + custom free text, stored as plain strings.
    var expectations: [String] = []

    /// `MediaAsset.id` of the chosen cover photo (auto-selected, user-editable).
    var coverAssetID: UUID?

    /// AI-derived fields; nil until generated (offline-safe, backfilled later).
    var theme: String?
    var headlineMemory: String?

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        destination: String = "",
        country: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        type: TripType = .solo,
        expectations: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.destination = destination
        self.country = country
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.expectations = expectations
        self.createdAt = createdAt
    }

    /// A trip is "active" when its date range contains the given day.
    /// Final active-trip resolution (most-recent fallback) lands in Phase 1.
    func isActive(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return calendar.startOfDay(for: startDate) <= day
            && day <= calendar.startOfDay(for: endDate)
    }
}
