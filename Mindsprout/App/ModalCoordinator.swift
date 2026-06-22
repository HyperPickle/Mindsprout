import SwiftUI

enum AppModal: Identifiable, Equatable {
    case newTrip
    case editTrip(tripID: UUID)
    case reflection(tripID: UUID)
    case todayReflection(reflectionID: UUID)
    case levelUp(LevelUpPresentation)
    case shop
    case themeSettings
    case aboutSettings
    case profilePhoto
    case account
    case xpDetail

    var id: String {
        switch self {
        case .newTrip: return "newTrip"
        case .editTrip(let tripID): return "editTrip-\(tripID.uuidString)"
        case .reflection(let tripID): return "reflection-\(tripID.uuidString)"
        case .todayReflection(let reflectionID): return "todayReflection-\(reflectionID.uuidString)"
        case .levelUp(let presentation): return "levelUp-\(presentation.id.uuidString)"
        case .shop: return "shop"
        case .themeSettings: return "themeSettings"
        case .aboutSettings: return "aboutSettings"
        case .profilePhoto: return "profilePhoto"
        case .account: return "account"
        case .xpDetail: return "xpDetail"
        }
    }

    /// Centered modals are rendered as a pop-in overlay (dimmed backdrop +
    /// scale/fade) instead of a bottom sheet.
    var prefersCenteredPresentation: Bool {
        switch self {
        case .account, .xpDetail: return true
        default: return false
        }
    }

    /// Modals presented edge-to-edge as a full-screen cover rather than a
    /// bottom sheet (e.g. the multi-step reflection creation flow).
    var prefersFullScreenCover: Bool {
        switch self {
        case .reflection: return true
        default: return false
        }
    }
}

@MainActor
@Observable
final class ModalCoordinator {
    var presented: AppModal?
    /// A milestone level-up that must be presented only *after* the reflection
    /// creation cover has finished dismissing. Consumed in the cover's
    /// `onDismiss` so the cinematic flow plays on a clean Home screen.
    var pendingLevelUp: LevelUpPresentation?

    func present(_ modal: AppModal) {
        presented = modal
    }

    func dismiss() {
        presented = nil
    }

    /// Closes the reflection creation cover, deferring any milestone level-up
    /// until the cover has fully dismissed.
    func finishReflection(_ completion: ReflectionCompletion) {
        switch completion {
        case .finish:
            pendingLevelUp = nil
        case .milestone(let presentation):
            pendingLevelUp = presentation
        }
        dismiss()
    }

    /// Presents a deferred milestone level-up, if one is pending. Call from the
    /// reflection cover's `onDismiss`.
    func presentPendingLevelUpIfNeeded() {
        guard let pendingLevelUp else { return }
        self.pendingLevelUp = nil
        present(.levelUp(pendingLevelUp))
    }
}
