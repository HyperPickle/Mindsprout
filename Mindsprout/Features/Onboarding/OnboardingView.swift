import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        // TODO: Onboarding design pending — build when designs land.
        ZStack {
            GrassBackground()
            VStack(spacing: Spacing.lg) {
                Spacer()
                Image(systemName: "leaf.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                Text("Welcome to Mindsprout")
                    .font(AppFont.title)
                    .foregroundStyle(.white)
                Text("Onboarding design pending.")
                    .font(AppFont.callout)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Button("Get Started", action: onFinish)
                    .buttonStyle(.primary)
                    .padding(.horizontal, Spacing.screenEdge)
                Button("Skip", action: onFinish)
                    .font(AppFont.callout)
                    .foregroundStyle(.white)
                    .padding(.bottom, Spacing.lg)
            }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
