import SwiftUI

extension View {
    func liquidGlass(cornerRadius: CGFloat = 10) -> some View {
        self
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .foregroundStyle(Color(hex: 0x5C6A6E))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}
