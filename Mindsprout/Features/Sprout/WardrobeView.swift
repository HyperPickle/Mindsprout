import SwiftUI
import RiveRuntime
import Combine

// MARK: - Glasses Type

enum SproutGlasses: Int, CaseIterable {
    case none = 0
    case heart = 1
    case round = 2

    var label: String {
        switch self {
        case .none:  return "None"
        case .heart: return "Heart"
        case .round: return "Round"
        }
    }
}

// MARK: - Wardrobe Category

private enum WardrobeCategory: CaseIterable {
    case all, glasses

    var icon: String {
        switch self {
        case .all:     return "square.grid.2x2.fill"
        case .glasses: return "eyeglasses"
        }
    }

    var label: String {
        switch self {
        case .all:     return "All"
        case .glasses: return "Glasses"
        }
    }
}

// MARK: - Wardrobe Rive Controller

@MainActor
final class WardrobeRiveController: ObservableObject {
    let riveVM: RiveViewModel
    private var isReady = false

    init() {
        riveVM = RiveViewModel(
            fileName: "sprouttest3",
            stateMachineName: "SproutHomeSM",
            fit: .contain,
            artboardName: "Sprout"
        )
    }

    func onAppear() {
        isReady = true
    }

    func setGlasses(_ type: SproutGlasses) {
        guard isReady else { return }
        // Option A – number input named "Glass" in SproutHomeSM (0 = none, 1 = heart, 2 = round)
        try? riveVM.setInput("Glass", value: Double(type.rawValue))

        // Option B – separate trigger inputs (uncomment and match your .riv input names)
        // let names = ["Empty", "Heart glass", "Round glass"]
        // try? riveVM.triggerInput(names[type.rawValue])
    }
}

// MARK: - WardrobeView

struct WardrobeView: View {
    @Binding var isPresented: Bool

    @Environment(ModalCoordinator.self) private var modalCoordinator

    @AppStorage("sproutGlassesChoice") private var savedGlasses: Int = 0
    @StateObject private var riveController = WardrobeRiveController()
    @State private var selectedGlasses: SproutGlasses = .none
    @State private var selectedCategory: WardrobeCategory = .all
    @State private var sproutScale: CGFloat = 0.88

    var body: some View {
        ZStack {
            BackgroundSky().ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top half: Sprout ──────────────────────────────────
                ZStack(alignment: .top) {
                    riveController.riveVM.view()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(sproutScale)
                        .onAppear {
                            riveController.onAppear()
                            // Small delay ensures Rive is fully initialized before setting input
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                riveController.setGlasses(selectedGlasses)
                            }
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                                sproutScale = 1.0
                            }
                        }

                    // Header buttons
                    HStack {
                        shopButton
                        Spacer()
                        closeButton
                    }
                    .padding(.top, 56)
                    .padding(.horizontal, Spacing.screenEdge)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Bottom half: Wardrobe panel ───────────────────────
                wardrobePanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectedGlasses = SproutGlasses(rawValue: savedGlasses) ?? .none
        }
    }

    // MARK: - Header Buttons

    private var closeButton: some View {
        Button {
            isPresented = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColor.label)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .readableLiquidGlass(in: Circle())
    }

    private var shopButton: some View {
        Button {
            modalCoordinator.present(.shop)
        } label: {
            Image(systemName: "bag.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.label)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .readableLiquidGlass(in: Circle())
    }

    // MARK: - Wardrobe Panel

    private var wardrobePanel: some View {
        VStack(spacing: 0) {
            // Category tab bar
            categoryBar
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

            Divider().opacity(0.4)

            // Content
            ScrollView(showsIndicators: false) {
                glassesGrid
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.vertical, Spacing.lg)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        HStack(spacing: 10) {
            ForEach(WardrobeCategory.allCases, id: \.self) { cat in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedCategory = cat
                    }
                } label: {
                    Image(systemName: cat.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(selectedCategory == cat ? AppColor.primary : Color(.secondaryLabel))
                        .frame(width: 46, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    selectedCategory == cat
                                        ? AppColor.primary.opacity(0.12)
                                        : Color(.systemFill)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            selectedCategory == cat ? AppColor.primary.opacity(0.35) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }
            Spacer()
        }
    }

    // MARK: - Glasses Grid

    private var glassesGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 12
        ) {
            ForEach(SproutGlasses.allCases, id: \.rawValue) { type in
                GlassesCell(type: type, isSelected: selectedGlasses == type) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedGlasses = type
                        savedGlasses = type.rawValue
                        riveController.setGlasses(type)
                    }
                }
            }
        }
    }
}

// MARK: - Glasses Cell

private struct GlassesCell: View {
    let type: SproutGlasses
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                cellIcon.frame(height: 76)

                Text(type.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? AppColor.primary : Color(.secondaryLabel))
            }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    @ViewBuilder
    private var cellIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(
                    isSelected
                        ? AppColor.primary.opacity(0.12)
                        : Color(.secondarySystemBackground).opacity(0.7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 2)
                )

            switch type {
            case .none:
                Text("NONE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? AppColor.primary : Color(.tertiaryLabel))

            case .heart:
                HStack(spacing: 3) {
                    Image("HeartGlass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                
                }
                .foregroundStyle(isSelected ? AppColor.primary : Color(.secondaryLabel))

            case .round:
                HStack(spacing: 4) {
                    Image("RoundGlass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                }
            }
        }
    }
}

#Preview {
    WardrobeView(isPresented: .constant(true))
        .environment(ModalCoordinator())
}
