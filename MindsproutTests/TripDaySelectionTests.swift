import Foundation
import Testing
@testable import Mindsprout

@MainActor
struct TripDaySelectionTests {
    @Test func selectedReflectionIDOpensMatchingDay() {
        let tripID = UUID()
        let day1 = Reflection(tripID: tripID, dayIndex: 1, isDraft: false)
        let day2 = Reflection(tripID: tripID, dayIndex: 2, isDraft: false)
        let day3 = Reflection(tripID: tripID, dayIndex: 3, isDraft: false)

        let index = TripDaySelection.initialIndex(
            in: [day1, day2, day3],
            selectedReflectionID: day2.id
        )

        #expect(index == 1)
    }

    @Test func selectedReflectionIDDoesNotAssumeContiguousDays() {
        let tripID = UUID()
        let day2 = Reflection(tripID: tripID, dayIndex: 2, isDraft: false)
        let day3 = Reflection(tripID: tripID, dayIndex: 3, isDraft: false)

        let index = TripDaySelection.initialIndex(
            in: [day2, day3],
            selectedReflectionID: day2.id
        )

        #expect(index == 0)
    }

    @Test func missingSelectionFallsBackToFirstReflection() {
        let tripID = UUID()
        let day1 = Reflection(tripID: tripID, dayIndex: 1, isDraft: false)

        let index = TripDaySelection.initialIndex(
            in: [day1],
            selectedReflectionID: UUID()
        )

        #expect(index == 0)
    }
}
