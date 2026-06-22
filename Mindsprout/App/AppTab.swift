import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case trips
    case home
    case profile

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .trips: return "Trips"
        case .home: return "Home"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .trips: return "airplane"
        case .home: return "leaf.fill"
        case .profile: return "person.fill"
        }
    }
}
