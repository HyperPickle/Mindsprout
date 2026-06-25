import SwiftUI

enum TripGlassSurfaceStyle: Equatable {
    case neutral
    case selected
    case cta(isEnabled: Bool)
    case danger
    case subtle
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 10) -> some View {
        readableLiquidGlass(
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }

    func readableLiquidGlass<S: InsettableShape>(
        in shape: S
    ) -> some View {
        modifier(
            ReadableLiquidGlassModifier(
                shape: shape
            )
        )
    }

    func tripGlassSurface<S: InsettableShape>(
        style: TripGlassSurfaceStyle = .neutral,
        in shape: S
    ) -> some View {
        modifier(
            TripGlassSurfaceModifier(
                shape: shape,
                style: style
            )
        )
    }
}

private struct ReadableLiquidGlassModifier<S: InsettableShape>: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let shape: S

    private var strokeColor: Color {
        .white.opacity(0.10)
    }

    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.10 : 0.12
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppColor.label)
            .glassEffect(in: shape)
            .overlay {
                shape
                    .strokeBorder(strokeColor, lineWidth: 1)
                    .opacity(colorScheme == .dark ? 1 : 0)
            }
            .shadow(color: .black.opacity(shadowOpacity), radius: 12, y: 4)
            .animation(.easeInOut(duration: 0.4), value: colorScheme)
    }
}

private struct TripGlassSurfaceModifier<S: InsettableShape>: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let shape: S
    let style: TripGlassSurfaceStyle

    func body(content: Content) -> some View {
        content
            .background(backgroundFill)
            .clipShape(shape)
            .glassEffect(in: shape)
            .overlay { tintOverlay }
            .overlay { highlightOverlay }
            .overlay { borderOverlay }
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowOffset)
            .animation(.easeInOut(duration: 0.25), value: style)
            .animation(.easeInOut(duration: 0.25), value: colorScheme)
    }

    @ViewBuilder private var backgroundFill: some View {
        shape
            .fill(baseFillColor)
    }

    @ViewBuilder private var tintOverlay: some View {
        if tintOpacity > 0 {
            shape
                .fill(tintColor.opacity(tintOpacity))
        }
    }

    @ViewBuilder private var highlightOverlay: some View {
        shape
            .strokeBorder(.white.opacity(highlightOpacity), lineWidth: 1)
    }

    @ViewBuilder private var borderOverlay: some View {
        if borderWidth > 0 {
            shape
                .strokeBorder(borderColor.opacity(borderOpacity), lineWidth: borderWidth)
        }
    }

    private var baseFillColor: Color {
        switch style {
        case .neutral:
            return colorScheme == .dark ? .white.opacity(0.05) : .white.opacity(0.10)
        case .selected:
            return colorScheme == .dark
                ? .white.opacity(0.10)
                : AppColor.skyTop.opacity(0.26)
        case .cta(let isEnabled):
            return isEnabled
                ? (colorScheme == .dark ? .white.opacity(0.16) : .white.opacity(0.20))
                : (colorScheme == .dark ? .white.opacity(0.05) : .white.opacity(0.08))
        case .danger:
            return colorScheme == .dark ? .white.opacity(0.10) : .white.opacity(0.16)
        case .subtle:
            return colorScheme == .dark ? .white.opacity(0.03) : .white.opacity(0.06)
        }
    }

    private var tintColor: Color {
        switch style {
        case .danger:
            return AppColor.destructive
        case .cta(let isEnabled):
            return isEnabled ? .white : .clear
        case .selected:
            return colorScheme == .dark ? AppColor.skyTop : AppColor.skyBottom
        case .neutral, .subtle:
            return .clear
        }
    }

    private var tintOpacity: Double {
        switch style {
        case .selected:
            return colorScheme == .dark ? 0.16 : 0.26
        case .cta(let isEnabled):
            return isEnabled ? (colorScheme == .dark ? 0.08 : 0.12) : 0
        case .danger:
            return colorScheme == .dark ? 0.16 : 0.12
        case .neutral, .subtle:
            return 0
        }
    }

    private var highlightOpacity: Double {
        switch style {
        case .neutral:
            return colorScheme == .dark ? 0.16 : 0.24
        case .selected:
            return colorScheme == .dark ? 0.22 : 0.34
        case .cta(let isEnabled):
            return isEnabled ? 0.30 : 0.16
        case .danger:
            return colorScheme == .dark ? 0.20 : 0.28
        case .subtle:
            return colorScheme == .dark ? 0.10 : 0.14
        }
    }

    private var borderColor: Color {
        switch style {
        case .selected:
            return colorScheme == .dark ? .white : AppColor.graphite
        case .cta:
            return colorScheme == .dark ? .white : AppColor.graphite
        case .danger:
            return AppColor.destructive
        case .neutral, .subtle:
            return .white
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .neutral:
            return colorScheme == .dark ? 0.8 : 0
        case .selected:
            return 2
        case .cta(let isEnabled):
            return isEnabled ? 1.3 : (colorScheme == .dark ? 0.8 : 0)
        case .danger:
            return 1.2
        case .subtle:
            return 0
        }
    }

    private var borderOpacity: Double {
        switch style {
        case .selected:
            return colorScheme == .dark ? 0.72 : 0.82
        case .cta(let isEnabled):
            return isEnabled ? (colorScheme == .dark ? 0.80 : 0.75) : 0.45
        case .danger:
            return colorScheme == .dark ? 0.80 : 0.65
        case .neutral:
            return 0.40
        case .subtle:
            return 0
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .cta(let isEnabled):
            return isEnabled ? 16 : 10
        case .selected:
            return 8
        case .danger:
            return 14
        case .neutral:
            return 12
        case .subtle:
            return 8
        }
    }

    private var shadowOpacity: Double {
        switch style {
        case .cta(let isEnabled):
            return isEnabled ? 0.18 : 0.08
        case .selected:
            return colorScheme == .dark ? 0.08 : 0.10
        case .danger:
            return 0.16
        case .neutral:
            return colorScheme == .dark ? 0.10 : 0.12
        case .subtle:
            return 0.06
        }
    }

    private var shadowOffset: CGFloat {
        switch style {
        case .cta(let isEnabled):
            return isEnabled ? 6 : 4
        case .danger, .neutral, .subtle:
            return 4
        case .selected:
            return 2
        }
    }
}
