//
//  Color+Hex.swift
//  Mindsprout
//
//  Convenience hex initializer used by the design-system palette.
//  Palette values are defined in code (see `AppColor`) so the whole
//  design system is previewable without round-tripping the asset catalog.
//  When final brand colors land they can move into `Assets.xcassets`
//  behind the same `AppColor` API with no feature-code changes.
//

import SwiftUI

extension Color {
    /// Creates a color from a 6-digit RGB hex value, e.g. `0x7FB84F`.
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
