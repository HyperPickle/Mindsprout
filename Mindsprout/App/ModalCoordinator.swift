import SwiftUI

enum AppModal: Identifiable, Equatable {
    case newTrip
    case levelUp(LevelUpPresentation)
    case shop
    case themeSettings
    case notificationsSettings
    case helpSupport
    case aboutSettings

    var id: String {
        switch self {
        case .newTrip: return "newTrip"
        case .levelUp(let presentation): return "levelUp-\(presentation.id.uuidString)"
        case .shop: return "shop"
        case .themeSettings: return "themeSettings"
        case .notificationsSettings: return "notificationsSettings"
        case .helpSupport: return "helpSupport"
        case .aboutSettings: return "aboutSettings"
        }
    }
}

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
