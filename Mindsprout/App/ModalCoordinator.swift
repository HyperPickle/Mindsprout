import SwiftUI

enum AppModal: Identifiable, Equatable {
    case newTrip
    case levelUp(LevelUpPresentation)
    case shop

    var id: String {
        switch self {
        case .newTrip: return "newTrip"
        case .levelUp(let presentation): return "levelUp-\(presentation.id.uuidString)"
        case .shop: return "shop"
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
