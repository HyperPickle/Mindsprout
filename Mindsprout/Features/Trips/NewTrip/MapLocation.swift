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
class NetworkMonitor: ObservableObject {
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
class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color(hex: 0x5C6A6E))
                    
                    TextField(
                        selectedCity.isEmpty ? "Search a city..." : selectedCity,
                        text: $searchText
                    )
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color(hex: 0x5C6A6E))
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        if network.isConnected {
                            searchDelegate.search(newValue)
                        }
                    }
                    
                    Spacer()
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            isFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(hex: 0x5C6A6E))
                        }
                    } else {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Color(hex: 0x5C6A6E))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8), in: .rect(cornerRadius: CornerRadius.medium))
                
                .overlay(alignment: .top) {
                    if showSuggestions {
                        VStack(alignment: .leading, spacing: 0) {
                            if network.isConnected {
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
                                        searchText = ""
                                        isFocused = false
                                        
                                        if let callback = onCoordinateSelected {
                                            let request = MKLocalSearch.Request(completion: result)
                                            MKLocalSearch(request: request).start { response, _ in
                                                if let coord = response?.mapItems.first?.placemark.coordinate {
                                                    callback(coord.latitude, coord.longitude)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if result.title != searchDelegate.results.prefix(6).last?.title {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            } else {
                                ForEach(offlineResults.prefix(6), id: \.self) { city in
                                    suggestionRow(
                                        title: city.components(separatedBy: ",").first ?? city,
                                        subtitle: city.components(separatedBy: ", ").dropFirst().joined(separator: ", ")
                                    ) {
                                        selectedCity = city
                                        searchText = ""
                                        isFocused = false
                                    }
                                    
                                    if city != offlineResults.prefix(6).last {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "wifi.slash")
                                        .font(.system(size: 10))
                                    Text("Offline — showing popular cities")
                                        .font(.system(size: 11, design: .rounded))
                                }
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                        .background(Color.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        .offset(y: 56)  // ← juste en dessous du TextField
                
                    }
                }
            }
            .zIndex(999)
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
                    .foregroundStyle(Color(hex: 0x5C6A6E))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.gray)
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
