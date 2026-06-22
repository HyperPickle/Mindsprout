import SwiftUI
import SwiftData

struct LevelUpFlow: View {
    let presentation: LevelUpPresentation

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var sprouts: [Sprout]
    @State private var step: Step = .sleeping

    private var sproutName: String { sprouts.first?.name.isEmpty == false ? sprouts.first!.name : "Sprout" }

    private enum Step: Int, CaseIterable {
        case sleeping
        case transition
        case evolved
        case insight
        case postcard
    }

    var body: some View {
        ZStack {
            Image("dashboard_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            content
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.bottom, Spacing.xl)
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.86), value: step)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .sleeping:
            sproutMoment(
                status: "\(sproutName) is feeling sleepy",
                title: "Something is stirring",
                subtitle: "\(presentation.destination) gave \(sproutName) enough energy to grow."
            )
        case .transition:
            transitionCard
        case .evolved:
            sproutMoment(
                status: "\(sproutName) evolved!",
                title: "Level \(presentation.newLevel)",
                subtitle: "\(sproutName) reached a new milestone."
            )
        case .insight:
            insightCard
        case .postcard:
            postcardCard
        }
    }

    private func sproutMoment(status: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Text(status)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.label)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Capsule().fill(AppColor.primaryEdge.opacity(0.58)))

            Image("sprout_stage0_idle")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 430)
                .scaleEffect(step == .evolved && !reduceMotion ? 1.04 : 1)
                .accessibilityHidden(true)

            rewardText(title: title, subtitle: subtitle)
            continueButton
        }
    }

    private var transitionCard: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppColor.currency)
                Text("A new layer unfolds")
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
                Text("The moment settles into \(sproutName), turning reflection into growth.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
            .background(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(.white.opacity(0.9)))
            continueButton
        }
    }

    private var insightCard: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(spacing: Spacing.md) {
                Text("Growth Insight")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.label)
                Text(presentation.insight.trait)
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
                Text(presentation.insight.blurb)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(.white.opacity(0.92)))
            continueButton
        }
    }

    private var postcardCard: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(presentation.postcard.title)
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.label)
                    .fixedSize(horizontal: false, vertical: true)
                Text(presentation.postcard.body)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.label)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                Text("Level \(presentation.previousLevel) → \(presentation.newLevel)")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.label)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(.white.opacity(0.94)))

            Button("Return Home") {
                dismiss()
            }
            .buttonStyle(.primary)
        }
    }

    private func rewardText(title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.22), radius: 4, y: 2)
            Text(subtitle)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.label.opacity(0.92))
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        }
    }

    private var continueButton: some View {
        Button(step == .postcard ? "Return Home" : "Continue") {
            advance()
        }
        .buttonStyle(.primary)
    }

    private func advance() {
        guard let currentIndex = Step.allCases.firstIndex(of: step) else { return }
        let nextIndex = Step.allCases.index(after: currentIndex)
        if nextIndex < Step.allCases.endIndex {
            step = Step.allCases[nextIndex]
        } else {
            dismiss()
        }
    }
}

#Preview {
    LevelUpFlow(
        presentation: LevelUpPresentation(
            destination: "Kyoto",
            previousLevel: 4,
            newLevel: 5,
            insight: GrowthInsight(trait: "Presence", blurb: "This moment leaned into presence."),
            postcard: Postcard(title: "Postcard from Kyoto", body: "You paused in Kyoto and noticed what mattered. Keep going.")
        )
    )
}
