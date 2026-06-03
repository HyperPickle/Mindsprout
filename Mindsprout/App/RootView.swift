//
//  RootView.swift
//  Mindsprout
//
//  The app shell: root TabView (Adventures / Home / Profile, Home centered),
//  the modal-flow presentation layer, and the first-launch onboarding gate.
//

import SwiftUI

struct RootView: View {
    /// Persisted onboarding completion flag (first-launch gate).
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var selection: AppTab = .home
    @State private var modalCoordinator = ModalCoordinator()

    let featureFlags: FeatureFlags

    init(featureFlags: FeatureFlags = .default) {
        self.featureFlags = featureFlags
    }

    /// Onboarding shows only when enabled and not yet completed.
    private var shouldShowOnboarding: Bool {
        featureFlags.onboardingEnabled && !hasCompletedOnboarding
    }

    var body: some View {
        @Bindable var coordinator = modalCoordinator

        TabView(selection: $selection) {
            Tab(AppTab.adventures.title, systemImage: AppTab.adventures.systemImage, value: AppTab.adventures) {
                AdventuresTab()
            }
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeTab()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileTab()
            }
        }
        .tint(AppColor.primary)
        .environment(modalCoordinator)
        // Phase 0: every flow presents as a sheet. Level-up becomes a
        // full-screen cover in Phase 4 — only this modifier changes.
        .sheet(item: $coordinator.presented) { modal in
            ModalContainer(modal: modal)
        }
        .fullScreenCover(isPresented: .constant(shouldShowOnboarding)) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    RootView()
        .environment(\.appEnvironment, .preview)
}
