//
//  ModalCoordinator.swift
//  Mindsprout
//
//  Scaffolding for the app's self-contained modal flows (New Trip, Reflection,
//  Level-up) and the Shop. Multi-step flows are presented modally over the tab
//  bar and own their internal navigation. Phase 0 wires presentation only; the
//  flows themselves are placeholders until their phases.
//

import SwiftUI

/// A modally-presented flow. `id` drives `.sheet(item:)` / `.fullScreenCover`.
enum AppModal: Identifiable, Hashable {
    /// New Trip creation flow (Phase 1).
    case newTrip
    /// Reflection capture flow for a trip (Phase 2).
    case reflection(tripID: UUID)
    /// Cinematic level-up / evolution sequence (Phase 4).
    case levelUp
    /// Shop, opened from the Home currency counter (Phase 6 placeholder).
    case shop

    var id: String {
        switch self {
        case .newTrip: return "newTrip"
        case .reflection(let tripID): return "reflection-\(tripID.uuidString)"
        case .levelUp: return "levelUp"
        case .shop: return "shop"
        }
    }
}

/// Owns which modal (if any) is currently presented. Injected into the
/// environment so any view can launch a flow.
@MainActor
@Observable
final class ModalCoordinator {
    var presented: AppModal?

    func present(_ modal: AppModal) {
        presented = modal
    }

    func dismiss() {
        presented = nil
    }
}
