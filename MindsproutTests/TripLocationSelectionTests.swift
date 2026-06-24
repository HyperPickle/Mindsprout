import Testing
@testable import Mindsprout

struct TripLocationSelectionTests {
    @Test func landmarkCandidateCollapsesToCityCountryDisplay() {
        let selection = TripLocationNormalizer.selection(
            from: TripLocationCandidate(
                title: "Sydney Harbour Bridge, NSW, Australia",
                locality: "Sydney",
                country: "Australia"
            )
        )

        #expect(selection?.displayName == "Sydney, Australia")
    }

    @Test func stateAndAdministrativeAreaAreOmitted() {
        let selection = TripLocationNormalizer.selection(
            from: TripLocationCandidate(
                title: "Sydney, New South Wales, Australia",
                locality: "Sydney",
                country: "Australia"
            )
        )

        #expect(selection?.city == "Sydney")
        #expect(selection?.country == "Australia")
        #expect(selection?.displayName == "Sydney, Australia")
    }

    @Test func candidatesWithoutLocalityOrCountryAreRejected() {
        let missingLocality = TripLocationNormalizer.selection(
            from: TripLocationCandidate(
                title: "Australia",
                locality: nil,
                country: "Australia"
            )
        )
        let missingCountry = TripLocationNormalizer.selection(
            from: TripLocationCandidate(
                title: "Sydney",
                locality: "Sydney",
                country: nil
            )
        )

        #expect(missingLocality == nil)
        #expect(missingCountry == nil)
    }

    @Test func duplicateCityCountrySelectionsProduceOneRow() throws {
        let selections = [
            try #require(TripLocationNormalizer.selection(city: "Sydney", country: "Australia")),
            try #require(TripLocationNormalizer.selection(city: "sydney", country: "australia")),
            try #require(TripLocationNormalizer.selection(city: "Kyoto", country: "Japan"))
        ]

        let deduplicated = TripLocationNormalizer.deduplicated(selections)

        #expect(deduplicated.map(\.displayName) == ["Sydney, Australia", "Kyoto, Japan"])
    }
}
