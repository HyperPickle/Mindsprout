import Foundation
import SwiftData

func todaysReflection(for trip: Trip, in context: ModelContext) -> Reflection? {
    let today = Calendar.current.startOfDay(for: Date())
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return nil }
    let tripID = trip.id
    let descriptor = FetchDescriptor<Reflection>(
        predicate: #Predicate { $0.tripID == tripID && $0.date >= today && $0.date < tomorrow }
    )
    return try? context.fetch(descriptor).first
}

func dayIndex(for trip: Trip, on date: Date = Date()) -> Int {
    let components = Calendar.current.dateComponents([.day], from: trip.startDate, to: date)
    return max(1, (components.day ?? 0) + 1)
}
