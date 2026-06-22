import SwiftUI

struct FloatingTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: AppTab
    
    private var centerTab: AppTab {
        selection == .home ? .home : .home
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            pill
            VStack(spacing: 4) {
                centerButton
                Text(centerTab.title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color(hex: 0xFFFFFF) : Color(hex: 0x6B4C2A))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: centerTab.title)
            }
            .offset(y: -10)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 25)
        .padding(.top, 28)   // reserves layout space for the circle floating above the pill
        .padding(.bottom, 0)
    }
    
    // MARK: - Pill
    
    private var pill: some View {
        HStack(spacing: 0) {
            sideItem(.trips)
            Spacer()
            Color.clear.frame(width: 72)
            Spacer()
            sideItem(.profile)
        }
        .padding(.horizontal, 24)  // ← réduit pour centrer les icônes
        .frame(height: 64)
        .glassEffect(in: Capsule())
    }
    

    
    // MARK: - Center Circle
    
    private var centerButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selection = centerTab
            }
        } label: {
            ZStack {
                Circle()
                    .fill(AppColor.pillSelected)
                    .frame(width: 70, height: 70)
                    .shadow(
                        color: AppColor.pillSelected.opacity(0.35),
                        radius: 12, x: 0, y: 6
                    )
                Image(systemName: centerTab.systemImage)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: centerTab)
    }
    
    // MARK: - Side Items
    
    private func sideItem(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppColor.primary : Color(.secondaryLabel))
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected ? AppColor.primary : Color(.secondaryLabel))
            }
            .frame(width: 100)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 45, style: .continuous)
                        .fill(AppColor.primary.opacity(0.14))
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .frame(width:145)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
// MARK: - Press Scale Button Style

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        BackgroundSky()
            .ignoresSafeArea()
        //Image("HomeBackground")
        VStack {
            Spacer()
            FloatingTabBar(selection: .constant(.home))
            FloatingTabBar(selection: .constant(.trips))
        }
    }
}
