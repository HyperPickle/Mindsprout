import Foundation
import SwiftData

/// Today's in-progress *draft* reflection for the given trip, if one exists.
/// The reflection creation flow resumes this draft; when none exists a fresh
/// reflection is started, which is what allows multiple reflections per day.
func todaysDraftReflection(for trip: Trip, in context: ModelContext) -> Reflection? {
    let today = Calendar.current.startOfDay(for: Date())
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return nil }
    let tripID = trip.id
    let descriptor = FetchDescriptor<Reflection>(
        predicate: #Predicate { $0.tripID == tripID && $0.isDraft == true && $0.date >= today && $0.date < tomorrow }
    )
    return try? context.fetch(descriptor).first
}

/// The most recent *completed* (non-draft) reflection for the given trip today,
/// if any. Used to gate the read-only "Today's Reflection" viewer (so drafts in
/// progress never surface there) and to pick the page it opens on.
func todaysCompletedReflection(for trip: Trip, in context: ModelContext) -> Reflection? {
    todaysCompletedReflections(for: trip, in: context).first
}

/// All of today's *completed* (non-draft) reflections for the given trip, most
/// recent first. Backs the modal's pager through the day's reflections.
func todaysCompletedReflections(for trip: Trip, in context: ModelContext) -> [Reflection] {
    let today = Calendar.current.startOfDay(for: Date())
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return [] }
    let tripID = trip.id
    let descriptor = FetchDescriptor<Reflection>(
        predicate: #Predicate { $0.tripID == tripID && $0.isDraft == false && $0.date >= today && $0.date < tomorrow },
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    return (try? context.fetch(descriptor)) ?? []
}

func dayIndex(for trip: Trip, on date: Date = Date()) -> Int {
    let components = Calendar.current.dateComponents([.day], from: trip.startDate, to: date)
    return max(1, (components.day ?? 0) + 1)
}
