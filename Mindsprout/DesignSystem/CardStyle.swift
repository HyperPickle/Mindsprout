//
//  CardStyle.swift
//  Mindsprout
//
//  The soft white rounded card used across Trips/Reflection screens.
//

import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .fill(AppColor.cardSurface)
            )
            .shadow(color: AppColor.ink.opacity(0.10), radius: 12, x: 0, y: 6)
    }
}

extension View {
    /// Wraps content in the standard Mindsprout card surface.
    func cardStyle(padding: CGFloat = Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
