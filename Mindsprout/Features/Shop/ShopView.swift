import SwiftUI

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // TODO: Shop design pending — currency sinks defined when designed.
            PlaceholderScreen(
                title: "Shop",
                systemImage: "bag",
                note: "Shop design pending."
            )
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ShopView()
}
