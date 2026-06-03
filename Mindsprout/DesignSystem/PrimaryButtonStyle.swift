//
//  PrimaryButtonStyle.swift
//  Mindsprout
//
//  The skeuomorphic green primary button from the scaffold (CONTINUE / Feed
//  Sprout): bright green face sitting on a darker green edge, white heavy
//  rounded label, a small press-down travel. Honors Reduce Motion.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Depth of the darker "edge" beneath the button face.
    private let edgeDepth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(AppFont.button)
            .textCase(.uppercase)
            .foregroundStyle(AppColor.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(AppColor.primary)
            )
            .background(
                // Darker edge peeking out below the face for the 3D feel.
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(AppColor.primaryEdge)
                    .offset(y: edgeDepth)
            )
            .offset(y: pressed ? edgeDepth : 0)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6),
                       value: pressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Primary green call-to-action button.
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
