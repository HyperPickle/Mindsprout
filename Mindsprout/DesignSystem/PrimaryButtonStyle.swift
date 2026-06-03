import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
