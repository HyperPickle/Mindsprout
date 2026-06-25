import SwiftUI
import SwiftData

struct ReflectionFlow: View {
    let tripID: UUID
    /// When true, shows a close control on the pre-submission steps that
    /// confirms before discarding the in-progress reflection. Used when the
    /// flow is hosted in a full-screen cover.
    var showsCloseControl = false
    var onComplete: ((ReflectionCompletion) -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ReflectionViewModel?
    @State private var showDiscardConfirmation = false

    private var isSubmitted: Bool {
        viewModel?.step == .reward
    }

    var body: some View {
        ZStack {
            BackgroundSky()

            VStack(spacing: 0) {
                if let vm = viewModel, showsCloseControl, !isSubmitted {
                    flowHeader(vm: vm)
                }
                Group {
                    if let vm = viewModel {
                        stepContent(vm: vm)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard)
        // Once the reflection is submitted (reward step) the flow can no longer
        // be backed out of interactively — only the reward CTA closes it.
        .interactiveDismissDisabled(isSubmitted)
        .confirmationDialog(
            "Discard this reflection?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                viewModel?.discardDraft()
                dismiss()
            }
            Button("Keep Writing", role: .cancel) {}
        } message: {
            Text("Your progress and any photos or audio will be removed.")
        }
        .task {
            guard viewModel == nil else { return }
            guard let pack = try? env.contentPackLoader.load() else { return }
            let tripDescriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tripID })
            let tripType = (try? context.fetch(tripDescriptor).first?.type) ?? .solo
            viewModel = ReflectionViewModel(
                tripID: tripID,
                context: context,
                contentPack: pack,
                mediaStore: env.mediaStore,
                gameConfig: env.gameConfig,
                ai: env.ai,
                transcriber: env.transcriber,
                tripType: tripType,
                onComplete: { completion in
                    if let onComplete {
                        viewModel = nil
                        onComplete(completion)
                    } else {
                        dismiss()
                    }
                }
            )
            viewModel?.onAppear()
        }
    }

    private func flowHeader(vm: ReflectionViewModel) -> some View {
        HStack(spacing: Spacing.xs) {
            Button {
                showDiscardConfirmation = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 56, height: 56)
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .accessibilityLabel("Close reflection")

            Text(stepTitle(for: vm))
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, Spacing.sm)
                .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private func stepTitle(for vm: ReflectionViewModel) -> String {
        switch vm.step {
        case .highlight: return "Today's highlight?"
        case .entry:     return "Capture"
        case .photos:    return "Add photos"
        case .reward:    return ""
        }
    }

    @ViewBuilder
    private func stepContent(vm: ReflectionViewModel) -> some View {
        switch vm.step {
        case .highlight:
            HighlightPickerStep(vm: vm)
        case .entry:
            EntryStep(vm: vm)
        case .photos:
            PhotoCommitStep(vm: vm)
        case .reward:
            ReflectionRewardStep(vm: vm)
        }
    }
}

/// Hosts the reflection creation flow inside Home's full-screen cover. Routes
/// completion through the coordinator so milestone level-ups are deferred until
/// the cover has finished dismissing.
struct ReflectionCoverFlow: View {
    let tripID: UUID
    @Environment(ModalCoordinator.self) private var coordinator

    var body: some View {
        ReflectionFlow(tripID: tripID, showsCloseControl: true) { completion in
            coordinator.finishReflection(completion)
        }
    }
}

#Preview {
    ReflectionFlow(tripID: UUID(), showsCloseControl: true)
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
}
