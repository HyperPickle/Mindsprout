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

    @Test func draftLookupReturnsNilWhenNoDraftToday() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        #expect(todaysDraftReflection(for: t, in: context) == nil)
    }

    @Test func draftLookupReturnsSameDayDraft() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let r = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: true)
        context.insert(r)
        try context.save()
        let found = todaysDraftReflection(for: t, in: context)
        #expect(found?.id == r.id)
    }

    @Test func draftLookupIgnoresCompletedReflection() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let r = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: false)
        context.insert(r)
        try context.save()
        #expect(todaysDraftReflection(for: t, in: context) == nil)
    }

    @Test func completedListReturnsAllTodaysReflectionsMostRecentFirst() throws {
        let context = makeContext()
        let t = trip()
        context.insert(t)
        let older = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: false,
                               createdAt: Date(timeIntervalSinceNow: -60))
        let newer = Reflection(tripID: t.id, dayIndex: 1, date: Date(), isDraft: false,
                               createdAt: Date())
        context.insert(older)
        context.insert(newer)
        try context.save()
        let all = todaysCompletedReflections(for: t, in: context)
        #expect(all.map(\.id) == [newer.id, older.id])
        // The singular accessor returns the most recent.
        #expect(todaysCompletedReflection(for: t, in: context)?.id == newer.id)
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
