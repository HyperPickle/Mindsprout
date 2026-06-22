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

    @Test func ctaDimensionsAreReducedByFifteenPercent() {
        let size = CGSize(width: 402, height: 874)
        let layout = HomeDashboardLayout(size: size)
        let currentCTAWidth = size.width - (Spacing.screenEdge * 2)

        #expect(layout.ctaWidth == currentCTAWidth * HomeDashboardLayout.ctaScale)
        #expect(layout.ctaHeight == HomeDashboardLayout.referenceCTAHeight * HomeDashboardLayout.ctaScale)
    }
}
