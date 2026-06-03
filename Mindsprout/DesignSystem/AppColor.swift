//
//  AppColor.swift
//  Mindsprout
//
//  Central color palette, reconstructed from the UI-Scaffold screenshots
//  (warm cream reflection screens, sky-blue Trips header, layered-grass Home,
//  skeuomorphic green primary button, brown rounded display ink).
//
//  Revisable: exact values are intent-matched from screenshots, not brand
//  tokens. Keep all color references going through this type so a future
//  asset-catalog / brand pass is a single-file change.
//

import SwiftUI

enum AppColor {
    // MARK: Surfaces / backgrounds
    /// Warm cream used behind reflection and modal flows.
    static let sand = Color(hex: 0xEFE7DA)
    /// Slightly lighter cream for raised cards on sand.
    static let cardSurface = Color(hex: 0xFCFAF5)
    /// Sky tones for the Trips header gradient.
    static let skyTop = Color(hex: 0xBFE3EF)
    static let skyBottom = Color(hex: 0xE9F4F2)
    /// Grass tones for the Home backdrop gradient.
    static let grassTop = Color(hex: 0x9BC56A)
    static let grassBottom = Color(hex: 0x5E8C3C)

    // MARK: Brand / actions
    /// Primary action green (Feed Sprout, Continue).
    static let primary = Color(hex: 0x7FB84F)
    /// Darker green used as the pressed-edge / shadow under the primary button.
    static let primaryEdge = Color(hex: 0x4F7A2E)
    /// Currency / coin accent.
    static let currency = Color(hex: 0xE8B84B)

    // MARK: Ink / text
    /// Primary text — warm brown matching the rounded display ink.
    static let ink = Color(hex: 0x5B4A38)
    /// Secondary / supporting text.
    static let inkSecondary = Color(hex: 0x8B7B68)
    /// Muted captions and metadata.
    static let inkMuted = Color(hex: 0xA89A86)
    /// Text drawn on top of the primary green.
    static let onPrimary = Color.white

    // MARK: Lines / fills
    static let hairline = Color(hex: 0xD9CFBF)
    /// Filled state of a selected segmented control / pill.
    static let pillSelected = Color(hex: 0x6E5A48)
    static let pillUnselected = Color(hex: 0xE7DECF)
}
