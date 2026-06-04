import SwiftUI

struct SignView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OnboardingView {
            dismiss()
        }
    }
}

#Preview {
    SignView()
}
