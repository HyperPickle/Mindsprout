import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case adventures
    case reflect
    case home
    case profile

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .adventures: return "Adventures"
        case .reflect: return "Reflect"
        case .home: return "Home"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .adventures: return "map"
        case .reflect: return "drop.fill"   // swap for custom watering can asset when available
        case .home: return "house.fill"
        case .profile: return "person.fill"
        }
    }
}
