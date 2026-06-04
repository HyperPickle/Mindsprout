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
        .background(AppColor.sand.ignoresSafeArea())
    }

    private var sproutHeader: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColor.primary)
                .frame(width: 52, height: 52)
                .background(Circle().fill(AppColor.primary.opacity(0.12)))
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("What was the highlight of your day?")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
                .background(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous).fill(.white))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(writeOwnExpanded && vm.selectedPrompt == nil && !customText.isEmpty
                                ? AppColor.primary : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            if writeOwnExpanded {
                TextField("Describe your highlight…", text: $customText, axis: .vertical)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
                    .focused($writeOwnFocused)
                    .padding(Spacing.md)
                    .background(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous).fill(.white))
                    .lineLimit(3...6)
                    .onChange(of: customText) { _, new in
                        vm.customPromptText = new
                        if !new.isEmpty { vm.clearPromptSelection() }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: writeOwnExpanded)
    }

    private var diceRow: some View {
        Button {
            vm.reshuffle()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "die.face.3.fill")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.inkSecondary)
                Text("Pull to refresh options")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.inkSecondary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button("Continue") {
            vm.step = 2
        }
        .buttonStyle(.primary)
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
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(prompt.title)
                        .font(AppFont.bodyEmphasized)
                        .foregroundStyle(AppColor.ink)
                    Text(prompt.subtitle)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.inkSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(AppFont.body)
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkSecondary)
            }
            .padding(Spacing.md)
            .background(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous).fill(.white))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 2)
            )
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
        tripType: .solo,
        onDismiss: {}
    )
    vm.shuffledPrompts = prompts
    return HighlightPickerStep(vm: vm)
        .environment(ModalCoordinator())
}
