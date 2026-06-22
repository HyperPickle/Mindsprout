import SwiftUI
import SwiftData

struct HighlightPickerStep: View {
    @Bindable var vm: ReflectionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var writeOwnExpanded = false
    @State private var customText = ""
    @State private var diceSpin = 0.0
    @State private var promptAnimationVersion = 0
    @FocusState private var writeOwnFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ReflectionStepHeader(title: "Today's highlight?")
                    promptCards
                    writeYourOwn
                    diceRow
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            continueButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var promptCards: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(vm.shuffledPrompts) { prompt in
                PromptCard(
                    prompt: prompt,
                    isSelected: vm.selectedPrompt?.id == prompt.id,
                    animationVersion: promptAnimationVersion
                ) {
                    vm.selectPrompt(prompt)
                    writeOwnExpanded = false
                    customText = ""
                    writeOwnFocused = false
                }
            }
        }
    }

    private var writeYourOwn: some View {
        VStack(spacing: 0) {
            Button {
                writeOwnExpanded.toggle()
                if writeOwnExpanded {
                    vm.clearPromptSelection()
                    writeOwnFocused = true
                }
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                    Text("Write your own")
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.label)
                    Spacer()
                    Image(systemName: writeOwnExpanded ? "chevron.up" : "chevron.right")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if writeOwnExpanded {
                Divider()
                    .background(AppColor.hairline)
                    .padding(.horizontal, Spacing.md)
                TextField("Describe your highlight…", text: $customText, axis: .vertical)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.label)
                    .focused($writeOwnFocused)
                    .padding(Spacing.md)
                    .lineLimit(3...6)
                    .onChange(of: customText) { _, new in
                        vm.customPromptText = new
                        if !new.isEmpty { vm.clearPromptSelection() }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .readableLiquidGlass(in: UnevenRoundedRectangle(
            topLeadingRadius: 12,
            bottomLeadingRadius: CornerRadius.large,
            bottomTrailingRadius: CornerRadius.large,
            topTrailingRadius: 12,
            style: .continuous
        ))
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: CornerRadius.large,
                bottomTrailingRadius: CornerRadius.large,
                topTrailingRadius: 12,
                style: .continuous
            )
            .stroke((writeOwnExpanded && vm.selectedPrompt == nil && !customText.isEmpty) ? Color.white : Color.clear, lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: writeOwnExpanded)
    }

    private var diceRow: some View {
        Button {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.4)) { diceSpin += 360 }
            }
            vm.reshuffle()
            promptAnimationVersion += 1
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "die.face.3.fill")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.label)
                    .rotationEffect(.degrees(diceSpin))
                Text("Refresh options")
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.label)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        HomeCTAButton(title: "Continue") {
            vm.step = .entry
        }
        .disabled(!vm.canContinueStep1)
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.bottom, Spacing.md)
    }
}

private struct PromptCard: View {
    let prompt: HighlightPrompt
    let isSelected: Bool
    let animationVersion: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                TypewriterText(
                    text: prompt.title,
                    animate: animationVersion > 0,
                    animationVersion: animationVersion
                )
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.label)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(AppFont.body)
                    .foregroundStyle(isSelected ? .white : AppColor.label)
            }
            .padding(Spacing.md)
            .frame(height: 76)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Reveals `text` one character at a time. Re-runs whenever `text` changes
/// (e.g. when prompts are refreshed). Respects Reduce Motion by showing the
/// full text immediately.
private struct TypewriterText: View {
    let text: String
    let animate: Bool
    let animationVersion: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = ""

    var body: some View {
        Text(shown)
            .task(id: taskKey) { await updateText() }
    }

    private var taskKey: String {
        "\(animationVersion)-\(text)"
    }

    private func updateText() async {
        guard animate, !reduceMotion else {
            shown = text
            return
        }

        shown = ""
        for character in text {
            shown.append(character)
            try? await Task.sleep(for: .milliseconds(31))
        }
    }
}

#Preview {
    let prompts: [HighlightPrompt] = [
        HighlightPrompt(id: "chat-local", title: "Chatted with someone who works or lives here", subtitle: "a cafe owner / shopkeeper / or neighbour..."),
        HighlightPrompt(id: "first-time", title: "Tried something for the first time", subtitle: "a food / an activity / a local ritual..."),
        HighlightPrompt(id: "got-lost", title: "Got genuinely lost", subtitle: "and found something better..."),
        HighlightPrompt(id: "quiet-spot", title: "Found a quiet spot", subtitle: "a bench / a cafe corner / a rooftop...")
    ]
    let vm = ReflectionViewModel(
        tripID: UUID(),
        context: { let c = PersistenceController.makeInMemoryContainer(); return ModelContext(c) }(),
        contentPack: ContentPack(
            prompts: PromptPack(highlightPrompts: ["default": prompts], inspirationPrompts: []),
            expectations: ExpectationPack(presets: [:])
        ),
        mediaStore: MediaStore(root: FileManager.default.temporaryDirectory),
        gameConfig: .default,
        ai: TemplateAIGenerationService(),
        transcriber: SpeechTranscriptionService(),
        tripType: .solo,
        onComplete: { _ in }
    )
    vm.shuffledPrompts = prompts
    return HighlightPickerStep(vm: vm)
        .environment(ModalCoordinator())
}
