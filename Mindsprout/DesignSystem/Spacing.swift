//
//  Spacing.swift
//  Mindsprout
//
//  Spacing and corner-radius tokens. No magic numbers in feature code —
//  layout values come from here.
//

import CoreGraphics

enum Spacing {
    /// 4pt
    static let xxs: CGFloat = 4
    /// 8pt
    static let xs: CGFloat = 8
    /// 12pt
    static let sm: CGFloat = 12
    /// 16pt
    static let md: CGFloat = 16
    /// 20pt — default screen edge inset.
    static let screenEdge: CGFloat = 20
    /// 24pt
    static let lg: CGFloat = 24
    /// 32pt
    static let xl: CGFloat = 32
    /// 48pt
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    /// 10pt — small chips / pills.
    static let small: CGFloat = 10
    /// 16pt — buttons.
    static let medium: CGFloat = 16
    /// 24pt — cards and sheets.
    static let large: CGFloat = 24
    /// Fully rounded.
    static let pill: CGFloat = 999
}
