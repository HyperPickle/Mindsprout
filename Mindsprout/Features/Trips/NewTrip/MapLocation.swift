//
//  MapLocation.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 4/6/2026.
//
import SwiftUI
import MapKit
import CoreLocation
import Combine
import Network

// MARK: - Network Monitor
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}

// MARK: - Location Search
@MainActor
final class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var results: [MKLocalSearchCompletion] = []
    let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(_ query: String) {
        completer.queryFragment = query
    }

    func clear() {
        completer.queryFragment = ""
        results = []
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
}

// MARK: - Offline Cities
private let offlineCities: [String] = [
    "Tokyo, Japan", "Paris, France", "London, United Kingdom",
    "New York, United States", "Rome, Italy", "Barcelona, Spain",
    "Amsterdam, Netherlands", "Berlin, Germany", "Sydney, Australia",
    "Bangkok, Thailand", "Singapore, Singapore", "Dubai, UAE",
    "Istanbul, Turkey", "Prague, Czech Republic", "Vienna, Austria",
    "Kyoto, Japan", "Osaka, Japan", "Seoul, South Korea",
    "Hong Kong, China", "Denpasar, Indonesia", "Lisbon, Portugal",
    "Athens, Greece", "Budapest, Hungary", "Copenhagen, Denmark",
    "Stockholm, Sweden", "Oslo, Norway", "Helsinki, Finland",
    "Zurich, Switzerland", "Brussels, Belgium", "Warsaw, Poland",
    "Mumbai, India", "Delhi, India", "Cairo, Egypt",
    "Cape Town, South Africa", "Rio de Janeiro, Brazil",
    "Buenos Aires, Argentina", "Mexico City, Mexico",
    "Toronto, Canada", "Vancouver, Canada", "Montreal, Canada",
    "Los Angeles, United States", "Chicago, United States",
    "San Francisco, United States", "Miami, United States",
    "Marrakech, Morocco", "Nairobi, Kenya", "Lagos, Nigeria"
]

// MARK: - Destination Picker View
struct DestinationPickerView: View {
    @Binding var selection: TripLocationSelection?
    
    @StateObject private var searchDelegate = LocationSearchDelegate()
    @StateObject private var network = NetworkMonitor()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var resolveTask: Task<Void, Never>?
    @State private var liveResults: [TripLocationSelection] = []
    @FocusState private var isFocused: Bool
    
    private var offlineResults: [TripLocationSelection] {
        guard !searchText.isEmpty else { return [] }
        return offlineCities.compactMap { city in
            let parts = city.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2,
                  city.localizedCaseInsensitiveContains(searchText) else { return nil }
            return TripLocationNormalizer.selection(city: parts[0], country: parts[1])
        }
    }
    
    private var showSuggestions: Bool {
        !searchText.isEmpty && isFocused
    }

    private var usesLiveSearch: Bool {
        guard network.isConnected else { return false }
#if targetEnvironment(simulator)
        return false
#else
        return true
#endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(AppColor.label)

                    TextField(
                        text: $searchText,
                        prompt: Text("Search a city...").foregroundStyle(AppColor.placeholder)
                    ) {}
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                        .tint(AppColor.label)
                        .focused($isFocused)
                        .onChange(of: searchText) { _, newValue in
                            if isFocused,
                               let selection,
                               !newValue.isEmpty,
                               newValue != selection.displayName {
                                self.selection = nil
                            }
                            scheduleSearch(for: newValue)
                        }

                    Spacer()

                    if !searchText.isEmpty {
                        Button {
                            clearSearch(resetSelection: true)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColor.label)
                        }
                    } else {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(AppColor.label)
                    }
                }
                .padding()
                .tripGlassSurface(
                    style: isFocused ? .selected : .neutral,
                    in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                )
                
                .overlay(alignment: .top) {
                    if showSuggestions {
                        VStack(alignment: .leading, spacing: 0) {
                            if usesLiveSearch {
                                ForEach(liveResults.prefix(6)) { location in
                                    suggestionRow(
                                        location: location
                                    ) {
                                        selection = location
                                        clearSearch()
                                    }
                                    
                                    if location.id != liveResults.prefix(6).last?.id {
                                        Divider()
                                            .overlay(AppColor.separator.opacity(0.45))
                                            .padding(.leading, 16)
                                    }
                                }
                            } else {
                                ForEach(offlineResults.prefix(6), id: \.self) { city in
                                    suggestionRow(
                                        location: city
                                    ) {
                                        selection = city
                                        clearSearch()
                                    }
                                    
                                    if city.id != offlineResults.prefix(6).last?.id {
                                        Divider()
                                            .overlay(AppColor.separator.opacity(0.45))
                                            .padding(.leading, 16)
                                    }
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: usesLiveSearch ? "wifi.slash" : "iphone.gen3.slash")
                                        .font(.system(size: 10))
                                    Text(usesLiveSearch ? "Offline — showing popular cities" : "Simulator fallback — showing popular cities")
                                        .font(AppFont.caption)
                                }
                                .foregroundStyle(AppColor.secondaryLabel)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.top, 6)
                        .background {
                            Color.clear
                                .tripGlassSurface(
                                    style: .neutral,
                                    in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                )
                        }
                        .offset(y: 56)
                
                    }
                }

                if let selection {
                    locationConfirmation(selection)
                        .padding(.top, Spacing.sm)
                }
            }
            .zIndex(999)
        }
        .onAppear {
            if searchText.isEmpty {
                searchText = selection?.displayName ?? ""
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused && searchText == selection?.displayName {
                searchText = ""
            } else if !focused && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchText = selection?.displayName ?? ""
            }
        }
        .onChange(of: selection) { _, newValue in
            if !isFocused {
                searchText = newValue?.displayName ?? ""
            }
        }
        .onChange(of: searchDelegate.results.map(\.stableLocationSearchID)) { _, _ in
            resolveLiveResults()
        }
        .onDisappear {
            searchTask?.cancel()
            resolveTask?.cancel()
        }
    }
    
    private func suggestionRow(
        location: TripLocationSelection,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColor.label)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.city)
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.label)
                    
                    Text(location.country)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func scheduleSearch(for query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard usesLiveSearch, trimmed.count >= 2 else {
            if trimmed.isEmpty || !usesLiveSearch {
                searchDelegate.clear()
                liveResults = []
            }
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            searchDelegate.search(trimmed)
        }
    }

    private func clearSearch(resetSelection: Bool = false) {
        searchTask?.cancel()
        resolveTask?.cancel()
        searchDelegate.clear()
        liveResults = []
        searchText = ""
        if resetSelection {
            selection = nil
        }
        isFocused = false
    }

    private func locationConfirmation(_ selection: TripLocationSelection) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .background(Circle().fill(AppColor.cardSurface))
                    .offset(x: 3, y: 3)
            }
            .foregroundStyle(AppColor.label)
            .frame(width: 22, height: 22)

            (
                Text("Trip location will be shown as")
                    .font(AppFont.callout)
                + Text(" ")
                    .font(AppFont.callout)
                + Text(selection.displayName)
                    .font(AppFont.bodyEmphasized)
                + Text(".")
                    .font(AppFont.callout)
            )
            .foregroundStyle(AppColor.label)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .tripGlassSurface(
            style: .selected,
            in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
        )
    }

    private func resolveLiveResults() {
        resolveTask?.cancel()

        let completions = searchDelegate.results
        guard usesLiveSearch, !completions.isEmpty else {
            liveResults = []
            return
        }

        resolveTask = Task { @MainActor in
            let resolved = await TripLocationMapResolver.resolve(completions)
            guard !Task.isCancelled else { return }
            liveResults = resolved
        }
    }
}

#Preview {
    ZStack {
        BackgroundSky()
        VStack {
            DestinationPickerView(selection: .constant(nil))
                .padding()
            Spacer()
        }
    }
}

private extension MKLocalSearchCompletion {
    var stableLocationSearchID: String {
        "\(title)|\(subtitle)"
    }
}

private enum TripLocationMapResolver {
    @MainActor
    static func resolve(_ completions: [MKLocalSearchCompletion]) async -> [TripLocationSelection] {
        var selections: [TripLocationSelection] = []

        for completion in completions {
            guard !Task.isCancelled,
                  let selection = await resolve(completion) else { continue }
            selections.append(selection)
        }

        return TripLocationNormalizer.deduplicated(selections)
    }

    @MainActor
    private static func resolve(_ completion: MKLocalSearchCompletion) async -> TripLocationSelection? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        guard let response = try? await search.start(),
              let item = response.mapItems.first,
              let selection = TripLocationNormalizer.selection(
                from: TripLocationCandidate(
                    title: item.name ?? completion.title,
                    locality: item.placemark.locality,
                    country: item.placemark.country
                )
              ) else { return nil }

        return await selectionWithCityCenterCoordinate(selection)
    }

    @MainActor
    private static func selectionWithCityCenterCoordinate(_ selection: TripLocationSelection) async -> TripLocationSelection {
        let geocoder = CLGeocoder()
        guard let placemarks = try? await geocoder.geocodeAddressString(selection.displayName),
              let placemark = placemarks.first,
              let coordinate = placemark.location?.coordinate else { return selection }

        return TripLocationSelection(
            city: selection.city,
            country: selection.country,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
