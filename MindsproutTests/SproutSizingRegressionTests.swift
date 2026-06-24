import CoreGraphics
import Testing
@testable import Mindsprout

@MainActor
struct SproutSizingRegressionTests {
    @Test func sproutViewCanRenderIdleStateWithoutSpriteKitSizingState() {
        let view = SproutView(state: .idle)

        #expect(view.state == .idle)
        #expect(view.draggable)
    }

    @Test func homeLayoutStillDocumentsLegacySproutNativeAspectRatio() {
        let layout = HomeDashboardLayout(size: CGSize(width: 402, height: 874))

        #expect(layout.sproutHeight == 400)
        #expect(layout.sproutWidth == 400 * HomeDashboardLayout.sproutAspectRatio)
    }
}
