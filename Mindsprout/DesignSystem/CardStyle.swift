import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .shadow(color: AppColor.label.opacity(0.10), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func cardStyle(padding: CGFloat = Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
