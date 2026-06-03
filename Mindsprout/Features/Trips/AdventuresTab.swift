//
//  AdventuresTab.swift
//  Mindsprout
//
//  Adventures tab → Trips. Phase 0 ships the NavigationStack + enum-route
//  plumbing with placeholder destinations; the real overview/detail and the
//  New Trip modal flow arrive in Phase 1.
//

import SwiftUI

/// Push destinations within the Adventures tab.
enum AdventuresRoute: Hashable {
    /// Per-day reflection viewer for a trip (Phase 1).
    case tripDetail(tripID: UUID)
}

struct AdventuresTab: View {
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var path: [AdventuresRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            PlaceholderScreen(
                title: "Adventures",
                systemImage: "airplane.departure",
                note: "Trips overview & detail — Phase 1."
            )
            .navigationTitle("Adventures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        modalCoordinator.present(.newTrip)
                    } label: {
                        Label("New trip", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: AdventuresRoute.self) { route in
                switch route {
                case .tripDetail:
                    PlaceholderScreen(
                        title: "Trip detail",
                        systemImage: "map",
                        note: "Day-by-day reflections — Phase 1."
                    )
                }
            }
        }
    }
}

#Preview {
    AdventuresTab()
        .environment(ModalCoordinator())
}
