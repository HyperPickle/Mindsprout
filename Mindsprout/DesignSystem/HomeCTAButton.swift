import SwiftUI

struct HomeCTAButton: View {
    static let referenceHeight: CGFloat = 72
    static let widthScale: CGFloat = 0.85
    static let height: CGFloat = referenceHeight * widthScale

    let title: LocalizedStringKey
    var widthScale: CGFloat = Self.widthScale
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        GeometryReader { proxy in
            Button(action: action) {
                Text(title)
                    .font(AppFont.homeCTA)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColor.label)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.height)
                    .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .frame(width: max(0, proxy.size.width) * widthScale, height: Self.height)
            .buttonStyle(.plain)
            .opacity(isEnabled ? 1 : 0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: Self.height)
    }
}
