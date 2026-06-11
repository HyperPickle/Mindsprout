import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID = UUID()
    var destination: String = ""
    var country: String = ""
    var latitude: Double?
    var longitude: Double?
    var startDate: Date = Date()
    var endDate: Date = Date()
    var type: TripType = TripType.solo
    var expectations: [String] = []
    var coverAssetID: UUID?
    var theme: String?
    var headlineMemory: String?
    var featuredReflectionID: UUID?
    var isManuallyActive: Bool = false
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        destination: String = "",
        country: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        startDate: Date = Date(),
        endDate: Date = Date(),
        type: TripType = .solo,
        expectations: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.destination = destination
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.expectations = expectations
        self.createdAt = createdAt
    }

    func isActive(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return calendar.startOfDay(for: startDate) <= day
            && day <= calendar.startOfDay(for: endDate)
    }
}
