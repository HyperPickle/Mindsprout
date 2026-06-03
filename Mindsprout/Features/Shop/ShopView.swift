//
//  ShopView.swift
//  Mindsprout
//
//  Shop — navigable placeholder, presented modally from the Home currency
//  counter. No design exists yet (Plan §2, Open Question #5/#7).
//

import SwiftUI

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // TODO: Shop design pending — currency sinks defined when designed.
            PlaceholderScreen(
                title: "Shop",
                systemImage: "bag",
                note: "Shop design pending."
            )
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ShopView()
}
