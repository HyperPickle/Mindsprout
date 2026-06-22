import Testing
import Foundation
@testable import Mindsprout

@MainActor
struct ModalCoordinatorTests {

    private func milestonePresentation() -> LevelUpPresentation {
        LevelUpPresentation.fallback(
            destination: "Kyoto",
            previousLevel: 4,
            newLevel: 5,
            context: ReflectionContext(
                tripType: .solo,
                destination: "Kyoto",
                highlightPrompt: "sunrise",
                text: "A quiet temple at dawn.",
                hasPhoto: true,
                hasAudio: false
            )
        )
    }

    @Test func ordinaryFinishDismissesWithoutPendingLevelUp() {
        let coordinator = ModalCoordinator()
        coordinator.present(.reflection(tripID: UUID()))

        coordinator.finishReflection(.finish)

        #expect(coordinator.presented == nil)
        #expect(coordinator.pendingLevelUp == nil)

        coordinator.presentPendingLevelUpIfNeeded()
        #expect(coordinator.presented == nil)
    }

    @Test func milestoneFinishDefersLevelUpUntilCoverDismisses() {
        let coordinator = ModalCoordinator()
        coordinator.present(.reflection(tripID: UUID()))
        let presentation = milestonePresentation()

        coordinator.finishReflection(.milestone(presentation))

        // Cover is dismissed first; level-up is staged, not yet presented.
        #expect(coordinator.presented == nil)
        #expect(coordinator.pendingLevelUp == presentation)

        // After the cover finishes dismissing, the level-up is presented and
        // the pending slot is cleared so it can't fire twice.
        coordinator.presentPendingLevelUpIfNeeded()
        #expect(coordinator.presented == .levelUp(presentation))
        #expect(coordinator.pendingLevelUp == nil)

        coordinator.presentPendingLevelUpIfNeeded()
        #expect(coordinator.presented == .levelUp(presentation))
    }

    @Test func fullScreenCoverRoutingOnlyForReflection() {
        #expect(AppModal.reflection(tripID: UUID()).prefersFullScreenCover)
        #expect(!AppModal.todayReflection(reflectionID: UUID()).prefersFullScreenCover)
        #expect(!AppModal.newTrip.prefersFullScreenCover)
    }
}
