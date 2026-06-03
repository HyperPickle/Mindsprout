//
//  ModalContainer.swift
//  Mindsprout
//
//  Renders the content for a presented `AppModal`. Phase 0 routes the three
//  flow modals to placeholders; the Shop placeholder is real (Phase 6 stub).
//  Real flows replace these cases in their respective phases with no change to
//  the presentation plumbing in `RootView`.
//

import SwiftUI

struct ModalContainer: View {
    let modal: AppModal

    var body: some View {
        switch modal {
        case .newTrip:
            FlowPlaceholder(
                title: "New Trip",
                systemImage: "plus.circle",
                note: "New Trip flow — Phase 1."
            )
        case .reflection:
            FlowPlaceholder(
                title: "Reflection",
                systemImage: "square.and.pencil",
                note: "Reflection capture — Phase 2."
            )
        case .levelUp:
            // Becomes a full-screen cinematic sequence in Phase 4.
            FlowPlaceholder(
                title: "Level Up",
                systemImage: "sparkles",
                note: "Level-up & evolution — Phase 4."
            )
        case .shop:
            ShopView()
        }
    }
}

/// A dismissable modal placeholder for not-yet-built flows.
private struct FlowPlaceholder: View {
    let title: LocalizedStringKey
    let systemImage: String
    let note: LocalizedStringKey
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PlaceholderScreen(title: title, systemImage: systemImage, note: note)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ModalContainer(modal: .newTrip)
}
