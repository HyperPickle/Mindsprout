import CoreGraphics
import SpriteKit
import Testing
@testable import Mindsprout

@MainActor
struct SproutSizingRegressionTests {
    @Test func idleStateRestoresNativeWidthAfterWidePose() {
        let scene = SproutScene(size: CGSize(width: 400, height: 600))
        let sprout = SKSpriteNode(color: .green, size: CGSize(width: 337, height: 400))
        sprout.position = CGPoint(x: 200, y: 300)
        scene.addChild(sprout)
        scene.sprout = sprout

        scene.startIdle()

        #expect(sprout.size.width == 400 * HomeDashboardLayout.sproutAspectRatio)
        #expect(sprout.size.height == 400)
    }
}
