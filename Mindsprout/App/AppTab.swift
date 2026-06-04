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
        case .adventures: return "airplane"
        case .reflect: return "book.pages"
        case .home: return "leaf.fill"
        case .profile: return "person.fill"
        }
    }
}
