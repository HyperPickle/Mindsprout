//
//  MapLocation.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 4/6/2026.
//
import SwiftUI
import MapKit
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
        completer.resultTypes = .address
    }
    
    func search(_ query: String) {
        completer.queryFragment = query
    }

    func clear() {
        completer.queryFragment = ""
        results = []
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter { result in
            let hasStreetNumber = result.title.first?.isNumber ?? false
            let hasCountry = !result.subtitle.isEmpty
            return !hasStreetNumber && hasCountry
        }
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
    "Hong Kong, China", "Bali, Indonesia", "Lisbon, Portugal",
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
    @Binding var selectedCity: String
    var onCoordinateSelected: ((Double, Double) -> Void)? = nil
    
    @StateObject private var searchDelegate = LocationSearchDelegate()
    @StateObject private var network = NetworkMonitor()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isFocused: Bool
    
    private var offlineResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return offlineCities.filter {
            $0.localizedCaseInsensitiveContains(searchText)
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
                                ForEach(searchDelegate.results.prefix(6), id: \.title) { result in
                                    suggestionRow(
                                        title: result.title,
                                        subtitle: result.subtitle
                                    ) {
                                        let country = result.subtitle
                                            .components(separatedBy: ",")
                                            .last?
                                            .trimmingCharacters(in: .whitespaces) ?? ""
                                        selectedCity = "\(result.title), \(country)"
                                        clearSearch()
                                        
                                        if let callback = onCoordinateSelected {
                                            let request = MKLocalSearch.Request(completion: result)
                                            MKLocalSearch(request: request).start { response, _ in
                                                if let coord = response?.mapItems.first?.location.coordinate {
                                                    callback(coord.latitude, coord.longitude)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if result.title != searchDelegate.results.prefix(6).last?.title {
                                        Divider()
                                            .overlay(AppColor.separator.opacity(0.45))
                                            .padding(.leading, 16)
                                    }
                                }
                            } else {
                                ForEach(offlineResults.prefix(6), id: \.self) { city in
                                    suggestionRow(
                                        title: city.components(separatedBy: ",").first ?? city,
                                        subtitle: city.components(separatedBy: ", ").dropFirst().joined(separator: ", ")
                                    ) {
                                        selectedCity = city
                                        clearSearch()
                                    }
                                    
                                    if city != offlineResults.prefix(6).last {
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
            }
            .zIndex(999)
        }
        .onAppear {
            if searchText.isEmpty {
                searchText = selectedCity
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused && searchText == selectedCity {
                searchText = ""
            } else if !focused && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchText = selectedCity
            }
        }
        .onChange(of: selectedCity) { _, newValue in
            if !isFocused {
                searchText = newValue
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }
    
    private func suggestionRow(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColor.label)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.label)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
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
        searchDelegate.clear()
        searchText = ""
        if resetSelection {
            selectedCity = ""
        }
        isFocused = false
    }
}

#Preview {
    ZStack {
        BackgroundSky()
        VStack {
            DestinationPickerView(selectedCity: .constant(""))
                .padding()
            Spacer()
        }
    }
}
