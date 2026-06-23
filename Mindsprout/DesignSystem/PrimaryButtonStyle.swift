import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = AppColor.primary
    var foreground: Color = Color.white
    var usesLiquidGlass = false
    var glassSurfaceStyle: ((Bool) -> TripGlassSurfaceStyle)? = nil
    var uppercased = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button)
            .textCase(uppercased ? .uppercase : nil)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background { backgroundView }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        let shape = RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)

        if let glassSurfaceStyle {
            Color.clear
                .tripGlassSurface(style: glassSurfaceStyle(isEnabled), in: shape)
        } else if usesLiquidGlass {
            Color.clear
                .readableLiquidGlass(in: shape)
        } else {
            shape.fill(fill)
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var primaryWhite: PrimaryButtonStyle {
        PrimaryButtonStyle(fill: .white, foreground: AppColor.label, usesLiquidGlass: true)
    }
    static var primaryWhiteSentenceCase: PrimaryButtonStyle {
        PrimaryButtonStyle(fill: .white, foreground: AppColor.label, usesLiquidGlass: true, uppercased: false)
    }
    static var tripGlassCTA: PrimaryButtonStyle {
        PrimaryButtonStyle(
            fill: .clear,
            foreground: AppColor.label,
            usesLiquidGlass: false,
            glassSurfaceStyle: { .cta(isEnabled: $0) }
        )
    }
}
