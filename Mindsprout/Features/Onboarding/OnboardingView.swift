//
//  OnboardingView.swift
//  Mindsprout
//
//  First-launch onboarding — navigable placeholder. Shown once before the tab
//  bar, flag-controlled and skippable; completion is persisted by the caller
//  (see `RootView`). No design exists yet (Plan §2, Open Question #5).
//

import SwiftUI

struct OnboardingView: View {
    /// Invoked when the user finishes or skips. Caller persists the flag.
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
