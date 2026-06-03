import SwiftUI

struct ModalContainer: View {
    let modal: AppModal

    var body: some View {
        switch modal {
        case .newTrip:
            NewTripFlow()
        case .reflection:
            FlowPlaceholder(
                title: "Reflection",
                systemImage: "square.and.pencil",
                note: "Reflection capture — Phase 2."
            )
        case .levelUp:
            FlowPlaceholder(
                title: "Level Up",
                systemImage: "sparkles",
                note: "Level-up & evolution — Phase 4."
            )
        case .shop:
            ShopView()
        }
    }
}

private struct FlowPlaceholder: View {
    let title: LocalizedStringKey
    let systemImage: String
    let note: LocalizedStringKey
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PlaceholderScreen(title: title, systemImage: systemImage, note: note)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ModalContainer(modal: .newTrip)
}
