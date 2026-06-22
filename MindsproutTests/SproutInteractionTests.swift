import CoreGraphics
import SpriteKit
import Testing
@testable import Mindsprout

@MainActor
struct SproutInteractionTests {
    @Test func dragContinuesAfterOriginalTouchPointLeavesMovedSprout() {
        let (scene, sprout) = makeScene()

        scene.beginInteraction(at: sprout.position, timestamp: 0)
        scene.updateInteraction(to: CGPoint(x: 220, y: 300))
        scene.updateInteraction(to: CGPoint(x: 390, y: 300))

        #expect(scene.isDragging)
        #expect(sprout.position == CGPoint(x: 390, y: 300))
    }

    @Test func dragCanTrackToEverySceneEdge() {
        let (scene, sprout) = makeScene()
        let edges = [
            CGPoint(x: 0, y: 300),
            CGPoint(x: 400, y: 300),
            CGPoint(x: 200, y: 0),
            CGPoint(x: 200, y: 600),
        ]

        scene.beginInteraction(at: sprout.position, timestamp: 0)
        scene.updateInteraction(to: CGPoint(x: 220, y: 300))

        for edge in edges {
            scene.updateInteraction(to: edge)
            #expect(sprout.position == edge)
        }
    }

    @Test func draggingCancelsSleepAnimationAndOwnsSpriteActions() {
        let (scene, sprout) = makeScene()
        scene.playSleepDaily()
        sprout.run(.repeatForever(.wait(forDuration: 1)), withKey: "sleepLoop")
        #expect(sprout.hasActions())

        scene.beginInteraction(at: sprout.position, timestamp: 0)
        scene.updateInteraction(to: CGPoint(x: 220, y: 300))

        #expect(scene.isDragging)
        #expect(sprout.action(forKey: "sleepLoop") == nil)
        #expect(sprout.action(forKey: "dragGrab") != nil)
    }

    @Test func stateUpdateCannotOverrideActiveDragAnimation() {
        let (scene, sprout) = makeScene()
        scene.beginInteraction(at: sprout.position, timestamp: 0)
        scene.updateInteraction(to: CGPoint(x: 220, y: 300))

        scene.updateState(.sleeping)

        #expect(scene.isDragging)
        #expect(sprout.action(forKey: "dragGrab") != nil)
    }

    @Test func returnMovementUsesEaseInEaseOut() {
        let (scene, _) = makeScene()

        let action = scene.makeReturnMovementAction(duration: 0.4)

        #expect(action.timingMode == .easeInEaseOut)
    }

    @Test func shortStationaryTouchStillRegistersAsTap() {
        let (scene, sprout) = makeScene()

        scene.beginInteraction(at: sprout.position, timestamp: 0)
        scene.endInteraction(at: sprout.position, timestamp: 0.1)

        #expect(!scene.isDragging)
        #expect(scene.tapCount == 1)
        #expect(sprout.action(forKey: "returnToCenter") == nil)
        scene.tapTimer?.invalidate()
    }

    @Test func cancelledDragReturnsSproutAndClearsDragState() {
        let (scene, sprout) = makeScene()

        scene.beginInteraction(at: sprout.position, timestamp: 0)
        scene.updateInteraction(to: CGPoint(x: 300, y: 300))
        scene.endInteraction(at: CGPoint(x: 300, y: 300), timestamp: 0.2, cancelled: true)

        #expect(!scene.isDragging)
        #expect(sprout.action(forKey: "returnToCenter") != nil)
    }

    @Test func sceneResizeRepositionsSproutAtConfiguredRestingPoint() {
        let (scene, sprout) = makeScene()
        scene.configurePresentation(scale: 1, restingVerticalOffset: -30)

        let oldSize = scene.size
        scene.size = CGSize(width: 500, height: 700)
        scene.didChangeSize(oldSize)

        #expect(sprout.position == CGPoint(x: 250, y: 380))
    }

    private func makeScene() -> (SproutScene, SKSpriteNode) {
        let scene = SproutScene(size: CGSize(width: 400, height: 600))
        let sprout = SKSpriteNode(color: .green, size: CGSize(width: 100, height: 100))
        sprout.position = CGPoint(x: 200, y: 300)
        scene.addChild(sprout)
        scene.sprout = sprout
        return (scene, sprout)
    }
}
