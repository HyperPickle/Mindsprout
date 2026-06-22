import SwiftUI
import SwiftData

/// Centered modal that expands the Profile XP card into a focused level and XP view.
struct XPDetailModal: View {
    @Environment(\.appEnvironment) private var env
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var sprouts: [Sprout]

    @State private var animateBar = false

    private var sprout: Sprout? { sprouts.first }

    private var level: Int { sprout?.level ?? 1 }
    private var totalXP: Int { sprout?.xp ?? 0 }

    private var progress: (within: Int, span: Int) {
        SproutProgressionEngine(config: env.gameConfig)
            .levelProgress(totalXP: totalXP, level: level)
    }

    private var isMaxLevel: Bool { progress.span <= 0 }

    private var fraction: Double {
        progress.span > 0 ? Double(progress.within) / Double(progress.span) : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header
            levelHero
            progressSection
        }
        .padding(Spacing.lg)
        .frame(maxWidth: 420)
        .liquidGlass(cornerRadius: CornerRadius.large)
        .onAppear {
            guard !reduceMotion else { animateBar = true; return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.12)) {
                animateBar = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            Button {
                modalCoordinator.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 36, height: 36)
            }
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer(minLength: 0)

            Text("Your Progress")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)

            Spacer(minLength: 0)

            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Level hero

    private var levelHero: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("Level")
                .font(AppFont.eyebrow)
                .foregroundStyle(AppColor.label.opacity(0.6))

            if isMaxLevel {
                Text("Max")
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.label)
            } else {
                Text("\(level)")
                    .font(AppFont.metricLarge)
                    .foregroundStyle(AppColor.label)
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            xpBar

            if isMaxLevel {
                Text("\(totalXP.formatted()) XP earned")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.label.opacity(0.72))
            } else {
                Text("\(progress.within.formatted()) / \(progress.span.formatted()) XP")
                    .font(AppFont.metric)
                    .foregroundStyle(AppColor.label)
                    .contentTransition(.numericText())
            }
        }
    }

    private var xpBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.07, green: 0.35, blue: 0.71).opacity(0.1))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppColor.currency.opacity(0.85), AppColor.currency],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(geo.size.width, geo.size.width * (animateBar ? fraction : 0))))
                    .shadow(color: AppColor.currency.opacity(0.4), radius: 4, y: 1)
            }
        }
        .frame(height: 18)
        .accessibilityElement()
        .accessibilityLabel("Experience progress")
        .accessibilityValue(
            isMaxLevel
                ? "Max level"
                : "\(progress.within) of \(progress.span) XP toward level \(level + 1)"
        )
    }
}

#Preview("Mid level") {
    ZStack {
        Color.black.opacity(0.35).ignoresSafeArea()
        XPDetailModal()
            .padding(.horizontal, Spacing.lg)
    }
    .environment(ModalCoordinator())
    .environment(\.appEnvironment, .preview)
    .modelContainer(for: [Sprout.self, User.self], inMemory: true)
}
