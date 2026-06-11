import SwiftUI

enum AppModal: Identifiable, Equatable {
    case newTrip
    case editTrip(tripID: UUID)
    case levelUp(LevelUpPresentation)
    case shop
    case themeSettings
    case helpSupport
    case aboutSettings
    case profilePhoto

    var id: String {
        switch self {
        case .newTrip: return "newTrip"
        case .editTrip(let tripID): return "editTrip-\(tripID.uuidString)"
        case .levelUp(let presentation): return "levelUp-\(presentation.id.uuidString)"
        case .shop: return "shop"
        case .themeSettings: return "themeSettings"
        case .helpSupport: return "helpSupport"
        case .aboutSettings: return "aboutSettings"
        case .profilePhoto: return "profilePhoto"
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
