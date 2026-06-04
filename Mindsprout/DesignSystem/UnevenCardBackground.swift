import SwiftUI

struct UnevenCardBackground: ViewModifier {
    var lineWidth: CGFloat = 0
    var strokeColor: Color = .clear

    func body(content: Content) -> some View {
        content
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: CornerRadius.large,
                    bottomTrailingRadius: CornerRadius.large,
                    topTrailingRadius: 12,
                    style: .continuous
                )
                .fill(.white)
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: CornerRadius.large,
                    bottomTrailingRadius: CornerRadius.large,
                    topTrailingRadius: 12,
                    style: .continuous
                )
                .stroke(strokeColor, lineWidth: lineWidth)
            )
            .shadow(color: AppColor.ink.opacity(0.08), radius: 8, y: 4)
    }
}

extension View {
    func unevenCardBackground(lineWidth: CGFloat = 0, strokeColor: Color = .clear) -> some View {
        modifier(UnevenCardBackground(lineWidth: lineWidth, strokeColor: strokeColor))
    }
}
