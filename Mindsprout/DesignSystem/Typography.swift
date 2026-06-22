import SwiftUI

enum AppFont {
    static let display = Font.system(.largeTitle, design: .rounded, weight: .semibold)
    static let screenTitle = Font.system(.title, design: .rounded, weight: .semibold)
    static let sectionTitle = Font.system(.title3, design: .rounded, weight: .semibold)
    static let bodyEmphasized = Font.system(.body, design: .rounded, weight: .medium)
    static let body = Font.system(.body, design: .rounded, weight: .regular)
    static let callout = Font.system(.callout, design: .rounded, weight: .medium)
    static let caption = Font.system(.footnote, design: .rounded, weight: .medium)
    static let eyebrow = Font.system(.caption2, design: .rounded, weight: .semibold)
    static let button = Font.system(.body, design: .rounded, weight: .bold)
    static let homeCTA = Font.system(.title3, design: .rounded, weight: .bold)
    static let metricLarge = Font.system(.largeTitle, design: .rounded, weight: .semibold).monospacedDigit()
    static let metric = Font.system(.headline, design: .rounded, weight: .semibold).monospacedDigit()
    static let timerLarge = Font.system(.title, design: .monospaced, weight: .light)
    static let timerCompact = Font.system(.title3, design: .monospaced, weight: .light)
}

// Seam for a bundled brand font: add the file + UIAppFonts, then swap the
// Font.system(...) calls above for Font.custom(...). No call-site changes.
enum FontRegistration {
    static func registerBundledFontsIfNeeded() {}
}
