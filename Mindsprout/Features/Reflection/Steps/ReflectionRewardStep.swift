import SwiftUI
import UIKit
import SwiftData
import SpriteKit
import RiveRuntime

struct ReflectionRewardAnimationPlan: Equatable {
    var initialXP: Int
    var finalXP: Int
    var shouldAnimateXP: Bool
    var shouldAnimateSprout: Bool

    init(reduceMotion: Bool, awardedXP: Int) {
        finalXP = max(0, awardedXP)
        if reduceMotion {
            initialXP = finalXP
            shouldAnimateXP = false
            shouldAnimateSprout = false
        } else {
            initialXP = 0
            shouldAnimateXP = finalXP > 0
            shouldAnimateSprout = true
        }
    }
}

struct ReflectionRewardStep: View {
    @Bindable var vm: ReflectionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var sprouts: [Sprout]
    @StateObject private var controller = SproutRiveController()
    @State private var displayedXP = 0
    @State private var lastRewardXP: Int?
    @State private var didPlayHaptic = false

    private var sproutName: String { sprouts.first?.name.isEmpty == false ? sprouts.first!.name : "Sprout" }

    private var rewardState: ReflectionRewardState? {
        vm.rewardState
    }

    private var animationPlan: ReflectionRewardAnimationPlan {
        ReflectionRewardAnimationPlan(
            reduceMotion: reduceMotion,
            awardedXP: rewardState?.xpAwarded ?? 0
        )
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("A moment worth keeping")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .liquidGlass(cornerRadius: 16)
                // Extra clearance so the Sprout jump animation's head doesn't clip into the title
                .padding(.bottom, Spacing.md)

            if let tagLine {
                Text(tagLine)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.label.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .liquidGlass(cornerRadius: 14)
            }

            sproutSection
                .frame(maxWidth: .infinity)
                .frame(height: 320, alignment: .bottom)

            Text(xpText)
                .font(AppFont.metricLarge)
                .foregroundStyle(AppColor.label)
                .contentTransition(.numericText())
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .liquidGlass(cornerRadius: 22)

            Text("Your reflection helped \(sproutName) grow.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.label.opacity(0.9))
                .multilineTextAlignment(.center)

            Spacer()

            Button(callToActionTitle) {
                vm.completeReward()
            }
            .buttonStyle(.primaryWhite)
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: rewardState?.xpAwarded) {
            await runCelebrationIfNeeded()
        }
    }

    @ViewBuilder
    private var sproutSection: some View {
        if animationPlan.shouldAnimateSprout {
            // Constrain to a width narrower than the 320 frame height so the
            // contained Rive artboard no longer fills the full height. This
            // leaves headroom above the Sprout for the level-up jump so its
            // head isn't clipped at the top frame edge.
            controller.riveVM.view()
                           .frame(width: 240, height: 300)
                           .allowsHitTesting(false)
        } else {
            Image("sprout_stage0_idle")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .accessibilityHidden(true)
        }
    }

    private var xpText: String {
        String(format: String(localized: "+%lld XP"), displayedXP)
    }

    private var tagLine: String? {
        guard let tag = rewardState?.tagLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tag.isEmpty else { return nil }
        return String(format: String(localized: "This reflection felt %@."), tag.lowercased())
    }

    private var callToActionTitle: String {
        rewardState?.isMilestone == true ? "See \(sproutName) Grow" : "Finish"
    }

    private func runCelebrationIfNeeded() async {
        guard let rewardState else { return }
        guard lastRewardXP != rewardState.xpAwarded else { return }

        lastRewardXP = rewardState.xpAwarded
        displayedXP = animationPlan.initialXP

        if !didPlayHaptic {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            didPlayHaptic = true
        }

        controller.updateState(.idle)
        if animationPlan.shouldAnimateSprout {
            controller.playLevelUp(willEvolve: false)
        }

        guard animationPlan.shouldAnimateXP else {
            displayedXP = animationPlan.finalXP
            return
        }

        let steps = max(1, min(animationPlan.finalXP, 24))
        let delay = UInt64(22_000_000)

        for step in 1...steps {
            let progress = Double(step) / Double(steps)
            displayedXP = max(1, Int((Double(animationPlan.finalXP) * progress).rounded()))
            try? await Task.sleep(nanoseconds: delay)
        }

        displayedXP = animationPlan.finalXP
    }
}

#Preview("Standard") {
    ReflectionRewardStep(vm: previewViewModel(isMilestone: false, xpAwarded: 10))
        .environment(\.appEnvironment, .preview)
}

#Preview("Milestone") {
    ReflectionRewardStep(vm: previewViewModel(isMilestone: true, xpAwarded: 10))
        .environment(\.appEnvironment, .preview)
}

@MainActor
private func previewViewModel(isMilestone: Bool, xpAwarded: Int) -> ReflectionViewModel {
    let container = PersistenceController.makeInMemoryContainer()
    let context = ModelContext(container)
    let vm = ReflectionViewModel(
        tripID: UUID(),
        context: context,
        contentPack: ContentPack(
            prompts: PromptPack(highlightPrompts: ["solo": []], inspirationPrompts: []),
            expectations: ExpectationPack(presets: [:])
        ),
        mediaStore: MediaStore(root: FileManager.default.temporaryDirectory),
        gameConfig: .default,
        ai: TemplateAIGenerationService(),
        transcriber: SpeechTranscriptionService(),
        tripType: .solo,
        onComplete: { _ in }
    )
    vm.step = .reward
    vm.rewardState = ReflectionRewardState(
        xpAwarded: xpAwarded,
        tagLabel: "Insightful",
        milestonePresentation: isMilestone
            ? LevelUpPresentation.fallback(
                destination: "Kyoto",
                previousLevel: 4,
                newLevel: 5,
                context: ReflectionContext(
                    tripType: .solo,
                    destination: "Kyoto",
                    highlightPrompt: "sunrise",
                    text: "A quiet temple at dawn.",
                    hasPhoto: true,
                    hasAudio: false
                )
            )
            : nil
    )
    return vm
}
