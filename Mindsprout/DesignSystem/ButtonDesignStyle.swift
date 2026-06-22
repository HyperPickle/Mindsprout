import SwiftUI

struct DepthButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var shadowColor: Color {
        colorScheme == .dark ? Color(hex: 0x9488A2): Color(hex:0x4CA9D0)
    }

    var textColor: Color {
        colorScheme == .dark ? Color(hex: 0x7E54B8): Color(hex:0x4ECBFA)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.sectionTitle)
            .foregroundColor(textColor)
            .frame(width: 320, height: 30)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color(shadowColor))
                        .offset(x: 0, y: 6)

                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.white)
                        .offset(y: configuration.isPressed ? 4 : 0)
                }
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
