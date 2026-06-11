import SwiftUI
import SwiftData

struct HighlightPickerStep: View {
    @Bindable var vm: ReflectionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var writeOwnExpanded = false
    @State private var customText = ""
    @FocusState private var writeOwnFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    sproutHeader
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
        .background(BackgroundSky())
    }

    private var sproutHeader: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            BlinkingSproutView()
                .frame(width: 95, height: 95)
            Text("What was the highlight of your day?")
                .font(AppFont.title)
                .foregroundStyle(AppColor.onBackground)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer()
        }
        .padding(.bottom, Spacing.sm)
    }

    private var promptCards: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(vm.shuffledPrompts) { prompt in
                PromptCard(
                    prompt: prompt,
                    isSelected: vm.selectedPrompt?.id == prompt.id
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
                        .foregroundStyle(AppColor.inkSecondary)
                    Text("Write your own")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Image(systemName: writeOwnExpanded ? "chevron.up" : "chevron.right")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.inkSecondary)
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
                    .foregroundStyle(AppColor.ink)
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
        .glassEffect(.regular.tint(.white), in: UnevenRoundedRectangle(
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
            .stroke((writeOwnExpanded && vm.selectedPrompt == nil && !customText.isEmpty) ? AppColor.primary : Color.clear, lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: writeOwnExpanded)
    }

    private var diceRow: some View {
        Button {
            vm.reshuffle()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "die.face.3.fill")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.onBackground)
                Text("Refresh options")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.onBackground)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button("Continue") {
            vm.step = 2
        }
        .buttonStyle(.primaryWhite)
        .disabled(!vm.canContinueStep1)
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.bottom, Spacing.md)
    }
}

private struct PromptCard: View {
    let prompt: HighlightPrompt
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(prompt.title)
                    .font(AppFont.bodyEmphasized)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(AppFont.body)
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkSecondary)
            }
            .padding(Spacing.md)
            .frame(height: 76)
            .glassEffect(.regular.tint(.white), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
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
        tripType: .solo,
        onDismiss: {}
    )
    vm.shuffledPrompts = prompts
    return HighlightPickerStep(vm: vm)
        .environment(ModalCoordinator())
}
