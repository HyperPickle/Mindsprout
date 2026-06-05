//
//  MapLocation.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 4/6/2026.
//

import SwiftUI
import MapKit
import Combine


// MAP NEEDS TO INTEGRATE AUTORISATION FOR LOCATION GPS


class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var results: [MKLocalSearchCompletion] = []
    let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address  // COUNTRY + CITY
    }
    
    func search(_ query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter{result in
            // Exclut les adresses avec numéro de rue
            let hasStreetNumber = result.title.first?.isNumber ?? false
            // Garde seulement si le subtitle contient un pays
            let hasCountry = !result.subtitle.isEmpty
            return !hasStreetNumber && hasCountry
            
        }
    }
}

struct LocationPickerView: View {
    @Binding var selectedCity: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchDelegate = LocationSearchDelegate()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                // Liste des résultats
                List(searchDelegate.results, id: \.title) { result in
                    Button {

                        let country = result.subtitle.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
                        selectedCity = "\(result.title), \(country)"
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary)
                            Text(result.subtitle)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color.gray)
                        }
                        .padding(.vertical, 4)
                    }
  
                    .overlay(alignment: .trailing) {
                        if selectedCity == result.title {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search a city...")
            .onChange(of: searchText) { _, newValue in
                searchDelegate.search(newValue)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

struct DestinationPickerView: View {
    @State private var showLocationPicker = false
    @Binding var selectedCity: String
    
    var body: some View {
        Button {
            showLocationPicker = true
        } label: {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color(hex: 0x5C6A6E))
                Text(selectedCity.isEmpty ? "Select Location" : selectedCity)
                    .foregroundStyle(Color(hex: 0x5C6A6E))
                Spacer()
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(.black)
            .padding()
            .background(Color.white.opacity(0.8), in: .rect(cornerRadius: 14))
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(selectedCity: $selectedCity)
        }
    }
}

#Preview{
    ZStack {
        BackgroundSky()
        DestinationPickerView(selectedCity: .constant(""))
    }
}
