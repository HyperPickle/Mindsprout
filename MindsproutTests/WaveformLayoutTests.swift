import CoreGraphics
import Testing
@testable import Mindsprout

struct WaveformLayoutTests {
    @Test func rejectsZeroAndNonFiniteContainerWidths() {
        #expect(WaveformLayout.barWidth(containerWidth: 0, barCount: 40) == nil)
        #expect(WaveformLayout.barWidth(containerWidth: -CGFloat.infinity, barCount: 40) == nil)
        #expect(WaveformLayout.barWidth(containerWidth: CGFloat.nan, barCount: 40) == nil)
    }

    @Test func rejectsContainersTooNarrowForWaveformSpacing() {
        #expect(WaveformLayout.barWidth(containerWidth: 20, barCount: 40) == nil)
        #expect(WaveformLayout.barWidth(containerWidth: 78, barCount: 40) == nil)
    }

    @Test func computesPositiveBarWidthForUsableLayouts() throws {
        let width = try #require(WaveformLayout.barWidth(containerWidth: 320, barCount: 40))
        #expect(width > 0)
        #expect(width == (CGFloat(320) - CGFloat(39) * WaveformLayout.spacing) / CGFloat(40))
    }
}
