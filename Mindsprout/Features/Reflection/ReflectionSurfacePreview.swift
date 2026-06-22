import SwiftUI

enum ReflectionSurfaceStyle {
    static let cardTextColor = AppColor.label
    static let secondaryCardTextOpacity = 0.6
    static let controlTextColor = AppColor.label
    static let decorativeIconColor = AppColor.inverseLabel
    static let mediaActionButtonWidth: CGFloat = 264
    static let mediaActionButtonIconLeadingPadding: CGFloat = Spacing.md
    static let mediaActionButtonIconSize: CGFloat = 16
}

extension View {
    func reflectionCardSurface<S: InsettableShape>(
        in shape: S
    ) -> some View {
        modifier(ReflectionCardSurfaceModifier(shape: shape))
    }

    func reflectionControlSurface<S: InsettableShape>(
        in shape: S
    ) -> some View {
        modifier(ReflectionControlSurfaceModifier(shape: shape))
    }
}

private struct ReflectionCardSurfaceModifier<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .readableLiquidGlass(in: shape)
    }
}

private struct ReflectionControlSurfaceModifier<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .readableLiquidGlass(in: shape)
    }
}
