import Testing
import Foundation
import SwiftData
@testable import Mindsprout

@MainActor
struct TripLocationViewModelTests {
    private func makeContext() -> ModelContext {
        ModelContext(PersistenceController.makeInMemoryContainer())
    }

    @Test func newTripSavePersistsCityCountryAndCoordinatesSeparately() throws {
        let context = makeContext()
        let viewModel = NewTripViewModel(now: Date(timeIntervalSince1970: 0))
        viewModel.type = .solo
        viewModel.locationSelection = TripLocationSelection(
            city: "Sydney",
            country: "Australia",
            latitude: -33.8688,
            longitude: 151.2093
        )

        let trip = try #require(viewModel.save(context: context))

        #expect(trip.destination == "Sydney")
        #expect(trip.country == "Australia")
        #expect(trip.latitude == -33.8688)
        #expect(trip.longitude == 151.2093)
    }

    @Test func newTripCannotSaveWithoutSelectedLocation() {
        let context = makeContext()
        let viewModel = NewTripViewModel()
        viewModel.type = .solo

        #expect(!viewModel.canContinue)
        #expect(viewModel.save(context: context) == nil)
    }

    @Test func editTripSaveIgnoresMissingLocationSelection() throws {
        let context = makeContext()
        let trip = Trip(
            destination: "Sydney Harbour Bridge",
            country: "Australia",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            type: .solo
        )
        context.insert(trip)
        try context.save()

        let viewModel = EditTripViewModel(tripID: trip.id)
        viewModel.load(context: context, pack: nil)
        viewModel.locationSelection = nil
        viewModel.save(context: context)

        #expect(trip.destination == "Sydney Harbour Bridge")
        #expect(trip.country == "Australia")
    }

    @Test func editTripLoadsExistingLocationUnchangedUntilEdited() throws {
        let context = makeContext()
        let trip = Trip(
            destination: "Sydney Harbour Bridge",
            country: "Australia",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            type: .solo
        )
        context.insert(trip)
        try context.save()

        let viewModel = EditTripViewModel(tripID: trip.id)
        viewModel.load(context: context, pack: nil)

        #expect(viewModel.locationSelection?.displayName == "Sydney Harbour Bridge, Australia")
        #expect(trip.destination == "Sydney Harbour Bridge")
        #expect(trip.country == "Australia")

        viewModel.locationSelection = TripLocationSelection(
            city: "Sydney",
            country: "Australia",
            latitude: -33.8688,
            longitude: 151.2093
        )
        viewModel.save(context: context)

        #expect(trip.destination == "Sydney")
        #expect(trip.country == "Australia")
        #expect(trip.latitude == -33.8688)
        #expect(trip.longitude == 151.2093)
    }
}
