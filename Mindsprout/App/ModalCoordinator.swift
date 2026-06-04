import SwiftUI

enum AppModal: Identifiable, Hashable {
    case newTrip
    case levelUp
    case shop

    var id: String {
        switch self {
        case .newTrip: return "newTrip"
        case .levelUp: return "levelUp"
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
