import Foundation
import SwiftData

@MainActor
@Observable
final class NewTripViewModel {
    var locationSelection: TripLocationSelection?
    var startDate: Date
    var endDate: Date
    var type: TripType? = nil
    var selectedExpectations: Set<String> = []
    var customExpectation = ""

    private let calendar = Calendar.current

    init(now: Date = Date()) {
        let today = Calendar.current.startOfDay(for: now)
        startDate = today
        endDate = Calendar.current.date(byAdding: .day, value: 6, to: today) ?? today
    }

    var durationDays: Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var canContinue: Bool {
        locationSelection != nil && endDate >= startDate && type != nil
    }

    var expectations: [String] {
        var result = Array(selectedExpectations)
        let custom = customExpectation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { result.append(custom) }
        return result
    }

    func presets(from pack: ContentPack) -> [String] {
        pack.expectations.presets(for: type ?? .solo)
    }

    func toggle(_ expectation: String) {
        if selectedExpectations.contains(expectation) {
            selectedExpectations.remove(expectation)
        } else {
            selectedExpectations.insert(expectation)
        }
    }

    @discardableResult
    func save(context: ModelContext) -> Trip? {
        guard let locationSelection else { return nil }

        return try? TripRepository(context: context).create(
            destination: locationSelection.city,
            country: locationSelection.country,
            latitude: locationSelection.latitude,
            longitude: locationSelection.longitude,
            startDate: startDate, endDate: endDate,
            type: type ?? .solo, expectations: expectations
        )
    }
}
