//
//  AppTab.swift
//  Mindsprout
//
//  The three root tabs. Order matches the design: Adventures, Home, Profile,
//  with Home centered as the primary destination.
//

import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case adventures
    case home
    case profile

    var id: Self { self }

    /// Localized tab title (routed through the String Catalog).
    var title: LocalizedStringKey {
        switch self {
        case .adventures: return "Adventures"
        case .home: return "Home"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .adventures: return "airplane"
        case .home: return "leaf.fill"
        case .profile: return "person.fill"
        }
    }
}
