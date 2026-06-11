import SwiftUI

extension View {
    func liquidGlass(cornerRadius: CGFloat = 10) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white)
            )
            .foregroundStyle(AppColor.ink)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
