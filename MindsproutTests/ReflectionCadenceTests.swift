import Testing
import Foundation
import SwiftData
@testable import Mindsprout

@MainActor
struct ReflectionCadenceTests {

    private func makeContext() -> ModelContext {
        ModelContext(PersistenceController.makeInMemoryContainer())
    }

    private func trip(startDate: Date = Calendar.current.startOfDay(for: Date())) -> Trip {
        Trip(destination: "Rome", country: "Italy", startDate: startDate, endDate: startDate.addingTimeInterval(7 * 86400))
    }

    @Test func returnsNilWhenNoReflectionToday() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        #expect(todaysReflection(for: t, in: context) == nil)
    }

    @Test func returnsSameDayDraft() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let r = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: true)
        context.insert(r)
        try context.save()
        let found = todaysReflection(for: t, in: context)
        #expect(found?.id == r.id)
    }

    @Test func doesNotReturnYesterdaysReflection() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let r = Reflection(tripID: t.id, dayIndex: 1, date: yesterday, isDraft: false)
        context.insert(r)
        try context.save()
        #expect(todaysReflection(for: t, in: context) == nil)
    }

    @Test func completedLookupReturnsTodaysSubmittedReflection() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let r = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: false)
        context.insert(r)
        try context.save()
        #expect(todaysCompletedReflection(for: t, in: context)?.id == r.id)
    }

    @Test func completedLookupIgnoresDraft() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let draft = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: true)
        context.insert(draft)
        try context.save()
        #expect(todaysCompletedReflection(for: t, in: context) == nil)
    }

    @Test func completedLookupIgnoresYesterdaysReflection() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let r = Reflection(tripID: t.id, dayIndex: 1, date: yesterday, isDraft: false)
        context.insert(r)
        try context.save()
        #expect(todaysCompletedReflection(for: t, in: context) == nil)
    }

    @Test func completedLookupIgnoresOtherTrip() throws {
        let context = makeContext()
        let t = trip()
        let other = trip()
        context.insert(t)
        context.insert(other)
        let r = Reflection(tripID: other.id, dayIndex: 1, date: Date(), isDraft: false)
        context.insert(r)
        try context.save()
        #expect(todaysCompletedReflection(for: t, in: context) == nil)
    }

    @Test func dayIndexSameDayIsOne() {
        let t = trip()
        #expect(dayIndex(for: t, on: t.startDate) == 1)
    }

    @Test func dayIndexAcrossMonthBoundary() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 31
        let jan31 = Calendar.current.date(from: components)!
        let t = trip(startDate: jan31)
        let feb1 = Calendar.current.date(byAdding: .day, value: 1, to: jan31)!
        #expect(dayIndex(for: t, on: feb1) == 2)
    }

    @Test func dayIndexNeverBelowOne() {
        let t = trip()
        let before = Calendar.current.date(byAdding: .day, value: -5, to: t.startDate)!
        #expect(dayIndex(for: t, on: before) == 1)
    }
}
