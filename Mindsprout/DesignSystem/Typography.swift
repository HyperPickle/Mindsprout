import SwiftUI

enum AppFont {
    static let display = Font.system(size: 34, weight: .heavy, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 20, weight: .bold, design: .rounded)
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 15, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let button = Font.system(size: 17, weight: .heavy, design: .rounded)
}

// Seam for a bundled brand font: add the file + UIAppFonts, then swap the
// Font.system(...) calls above for Font.custom(...). No call-site changes.
enum FontRegistration {
    static func registerBundledFontsIfNeeded() {}
}
