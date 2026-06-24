import CoreGraphics
import Testing
@testable import Mindsprout

@MainActor
struct SproutInteractionTests {
    @Test func dragLifecycleIsOwnedByRiveController() {
        let controller = SproutRiveController()

        #expect(!controller.isDragging)

        controller.onGrabBegan()
        #expect(controller.isDragging)

        controller.onDropped()
        #expect(!controller.isDragging)
    }

    @Test func repeatedGrabDoesNotToggleDragStateOff() {
        let controller = SproutRiveController()

        controller.onGrabBegan()
        controller.onGrabBegan()

        #expect(controller.isDragging)
    }

    @Test func stateUpdatesCannotClearActiveDrag() {
        let controller = SproutRiveController()
        controller.onViewAppeared()
        controller.onGrabBegan()

        controller.updateState(.sleeping)

        #expect(controller.isDragging)
    }

    @Test func sproutViewDefaultsToDraggableHomeInteraction() {
        let view = SproutView(state: .idle)

        #expect(view.state == .idle)
        #expect(view.draggable)
    }
}
