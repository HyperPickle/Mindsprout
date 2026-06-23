import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case trips
    case reflect
    case home
    case profile

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .trips: return "Trips"
        case .reflect: return "Reflect"
        case .home: return "Home"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .trips: return "airplane"
        case .reflect: return "leaf.fill"
        case .home: return "house.fill"
        case .profile: return "person.fill"
        }
    }
}
