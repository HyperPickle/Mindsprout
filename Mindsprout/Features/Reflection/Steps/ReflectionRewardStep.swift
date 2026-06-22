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
            Spacer(minLength: Spacing.xl)

            Text("A moment worth keeping")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)

            sproutSection
                .frame(maxWidth: .infinity)
                .frame(height: 320)

            Text(xpText)
                .font(AppFont.metricLarge)
                .foregroundStyle(AppColor.label)
                .contentTransition(.numericText())

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
            controller.riveVM.view()
                           .frame(maxWidth: .infinity, maxHeight: .infinity)
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
