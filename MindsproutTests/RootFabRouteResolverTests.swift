import Foundation
import Testing
@testable import Mindsprout

struct RootFabRouteResolverTests {
    @Test func tripsTabKeepsReflectRoutingWhenTripsExist() {
        let tripID = UUID()
        let reflectionID = UUID()

        #expect(
            RootFabRouteResolver.presentation(
                for: .trips,
                reflectAction: .startReflection,
                activeTripID: tripID
            ) == .reflection(tripID: tripID)
        )
        #expect(
            RootFabRouteResolver.presentation(
                for: .trips,
                reflectAction: .viewTodayReflection(reflectionID: reflectionID),
                activeTripID: tripID
            ) == .todayReflection(reflectionID: reflectionID)
        )
    }

    @Test func tripsTabRoutesToNewTripWhenNoTripExists() {
        #expect(
            RootFabRouteResolver.presentation(
                for: .trips,
                reflectAction: .createTrip,
                activeTripID: nil
            ) == .newTrip
        )
    }

    @Test func nonTripsTabKeepsReflectRoutingWhenTripIsActive() {
        let tripID = UUID()

        #expect(
            RootFabRouteResolver.presentation(
                for: .home,
                reflectAction: .startReflection,
                activeTripID: tripID
            ) == .reflection(tripID: tripID)
        )
    }

    @Test func nonTripsTabRoutesToNewTripWhenNoTripExists() {
        #expect(
            RootFabRouteResolver.presentation(
                for: .home,
                reflectAction: .createTrip,
                activeTripID: nil
            ) == .newTrip
        )
    }
}
