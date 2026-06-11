import Foundation
import SwiftData

@MainActor
@Observable
final class EditTripViewModel {
    let tripID: UUID

    var destination = ""
    var latitude: Double? = nil
    var longitude: Double? = nil
    var startDate = Date()
    var endDate = Date()
    var type: TripType = .solo
    var selectedExpectations: Set<String> = []
    var customExpectation = ""
    var featuredReflectionID: UUID?
    var makeActive = false

    private(set) var reflections: [Reflection] = []
    private(set) var activeOtherTripName: String?
    private var presets: [String] = []
    private var trip: Trip?

    private let calendar = Calendar.current

    init(tripID: UUID) { self.tripID = tripID }

    var durationDays: Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var canSave: Bool {
        !destination.trimmingCharacters(in: .whitespaces).isEmpty && endDate >= startDate
    }

    /// True when turning the active toggle on would displace a different active trip.
    var needsActiveConfirmation: Bool { activeOtherTripName != nil }

    func presetOptions() -> [String] { presets }

    func load(context: ModelContext, pack: ContentPack?) {
        let repo = TripRepository(context: context)
        guard let trips = try? repo.allTrips(),
              let trip = trips.first(where: { $0.id == tripID }) else { return }
        self.trip = trip

        destination = trip.country.isEmpty ? trip.destination : "\(trip.destination), \(trip.country)"
        latitude = trip.latitude
        longitude = trip.longitude
        startDate = trip.startDate
        endDate = trip.endDate
        type = trip.type
        featuredReflectionID = trip.featuredReflectionID
        reflections = (try? repo.reflections(for: trip)) ?? []

        presets = pack?.expectations.presets(for: trip.type) ?? []
        let presetSet = Set(presets)
        selectedExpectations = Set(trip.expectations.filter { presetSet.contains($0) })
        customExpectation = trip.expectations.filter { !presetSet.contains($0) }.joined(separator: ", ")

        let resolvedActive = TripResolver.active(in: trips)
        makeActive = resolvedActive?.id == tripID
        if let other = resolvedActive, other.id != tripID {
            activeOtherTripName = other.destination
        } else {
            activeOtherTripName = nil
        }
    }

    func toggle(_ expectation: String) {
        if selectedExpectations.contains(expectation) {
            selectedExpectations.remove(expectation)
        } else {
            selectedExpectations.insert(expectation)
        }
    }

    func toggleFeatured(_ id: UUID) {
        featuredReflectionID = (featuredReflectionID == id) ? nil : id
    }

    private var expectations: [String] {
        var result = Array(selectedExpectations)
        let custom = customExpectation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { result.append(custom) }
        return result
    }

    func save(context: ModelContext) {
        guard let trip else { return }
        let parts = destination.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        trip.destination = parts.first ?? destination.trimmingCharacters(in: .whitespaces)
        trip.country = parts.count > 1 ? parts[1] : ""
        trip.latitude = latitude
        trip.longitude = longitude
        trip.startDate = startDate
        trip.endDate = endDate
        trip.type = type
        trip.expectations = expectations
        trip.featuredReflectionID = featuredReflectionID

        if makeActive {
            if let trips = try? TripRepository(context: context).allTrips() {
                for other in trips where other.id != tripID { other.isManuallyActive = false }
            }
            trip.isManuallyActive = true
        } else {
            trip.isManuallyActive = false
        }
        try? context.save()
    }

    func delete(context: ModelContext) {
        guard let trip else { return }
        try? TripRepository(context: context).delete(trip)
    }
}
