import SwiftUI
import SwiftData

struct ReflectionFlow: View {
    let tripID: UUID
    var onComplete: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ReflectionViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                stepContent(vm: vm)
            } else {
                SandBackground().ignoresSafeArea()
            }
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
                tripType: tripType,
                onDismiss: {
                    if let onComplete {
                        onComplete()
                    } else {
                        dismiss()
                    }
                }
            )
            viewModel?.onAppear()
        }
    }

    @ViewBuilder
    private func stepContent(vm: ReflectionViewModel) -> some View {
        switch vm.step {
        case 1:
            HighlightPickerStep(vm: vm)
        case 2:
            EntryStep(vm: vm)
        case 3:
            PhotoCommitStep(vm: vm)
        default:
            EmptyView()
        }
    }
}

#Preview {
    ReflectionFlow(tripID: UUID())
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
}
