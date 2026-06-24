import Foundation

struct TripLocationSelection: Hashable, Identifiable {
    var city: String
    var country: String
    var latitude: Double?
    var longitude: Double?

    var id: String { normalizedKey }
    var displayName: String { "\(city), \(country)" }

    var normalizedKey: String {
        "\(city.normalizedLocationComponent)|\(country.normalizedLocationComponent)"
    }
}

struct TripLocationCandidate {
    var title: String
    var locality: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
}

enum TripLocationNormalizer {
    static func selection(
        city: String,
        country: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> TripLocationSelection? {
        let city = city.normalizedDisplayLocationComponent
        let country = country.normalizedDisplayLocationComponent
        guard !city.isEmpty, !country.isEmpty else { return nil }
        return TripLocationSelection(city: city, country: country, latitude: latitude, longitude: longitude)
    }

    static func selection(from candidate: TripLocationCandidate) -> TripLocationSelection? {
        guard let locality = candidate.locality,
              let country = candidate.country else { return nil }

        return selection(
            city: locality,
            country: country,
            latitude: candidate.latitude,
            longitude: candidate.longitude
        )
    }

    static func deduplicated(_ selections: [TripLocationSelection]) -> [TripLocationSelection] {
        var seen: Set<String> = []
        var result: [TripLocationSelection] = []

        for selection in selections {
            guard !seen.contains(selection.normalizedKey) else { continue }
            seen.insert(selection.normalizedKey)
            result.append(selection)
        }

        return result
    }
}

private extension String {
    var normalizedDisplayLocationComponent: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    var normalizedLocationComponent: String {
        normalizedDisplayLocationComponent
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
