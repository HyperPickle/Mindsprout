import CoreGraphics
import Testing
@testable import Mindsprout

struct HomeDashboardLayoutTests {
    @Test func sproutViewportMatchesDashboardSize() {
        let size = CGSize(width: 402, height: 874)
        let layout = HomeDashboardLayout(size: size)

        #expect(layout.sproutViewportSize == size)
    }

    @Test func sproutUsesNativeAspectRatioAtFourHundredPointReferenceHeight() {
        let layout = HomeDashboardLayout(size: CGSize(width: 402, height: 874))

        #expect(layout.sproutHeight == 400)
        #expect(layout.sproutWidth == 400 * HomeDashboardLayout.sproutAspectRatio)
    }

    @Test func tripPillUsesReferenceTopRowGeometry() {
        let size = CGSize(width: 402, height: 874)
        let layout = HomeDashboardLayout(size: size)

        #expect(layout.topRowCenterY == 50)
        #expect(layout.tripGroupCenterX == 178)
        #expect(layout.tripGroupMaxWidth == 340)
        #expect(layout.tripPillHeight == 104)
    }
}
