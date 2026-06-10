
import SwiftUI

struct TravelTypeButton: View {
    let type: OnboardingCoordinator.TravelType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.white)
                    .frame(width: 73, height: 73)
                    .background(
                        isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.8),
                        in: .rect(cornerRadius: CornerRadius.medium)
                    )
                VStack {
                    Image(type.icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(isSelected ? Color.white : Color(hex: 0x5C6A6E))
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white : Color(hex: 0x5C6A6E))
                }
            }
        }
    }
}

#Preview {
    ZStack {
        BackgroundSky()
        HStack(spacing: 20) {
            TravelTypeButton(type: .solo, isSelected: false, action: {})
            TravelTypeButton(type: .family, isSelected: true, action: {})
        }
    }
}
