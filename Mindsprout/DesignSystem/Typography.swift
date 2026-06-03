//
//  Typography.swift
//  Mindsprout
//
//  Type system. The designs use a rounded display face; until a bundled
//  custom font lands we use the system rounded design, which matches the
//  intent closely and ships with no asset. `FontRegistration` documents the
//  seam for dropping in a custom `.otf`/`.ttf` later with no call-site changes.
//

import SwiftUI

enum AppFont {
    /// Big numerals / hero moments ("Level Up 3", currency).
    static let display = Font.system(size: 34, weight: .heavy, design: .rounded)
    /// Screen titles.
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    /// Section headers / card titles.
    static let headline = Font.system(size: 20, weight: .bold, design: .rounded)
    /// Emphasized body (prompts, CTAs).
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold, design: .rounded)
    /// Default body text.
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    /// Supporting text.
    static let callout = Font.system(size: 15, weight: .medium, design: .rounded)
    /// Metadata, counters, labels.
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    /// Button label.
    static let button = Font.system(size: 17, weight: .heavy, design: .rounded)
}

/// Seam for registering a bundled custom display font.
///
/// When the brand font is delivered:
///   1. Add the font file (e.g. `Mindsprout-Display.otf`) to `Resources/Fonts/`.
///   2. Add `UIAppFonts` (Fonts provided by application) to the Info.plist build
///      settings with the file name.
///   3. Replace the `Font.system(... design: .rounded)` calls in `AppFont` with
///      `Font.custom("PostScriptName", size:)` — no feature code changes.
enum FontRegistration {
    /// Currently a no-op: the system rounded face needs no registration.
    /// Call from `MindsproutApp.init()` once a bundled font exists.
    static func registerBundledFontsIfNeeded() {
        // TODO: register custom display font when the asset is delivered.
    }
}
