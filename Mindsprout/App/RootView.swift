import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var selection: AppTab = .home
    @State private var modalCoordinator = ModalCoordinator()

    let featureFlags: FeatureFlags

    init(featureFlags: FeatureFlags = .default) {
        self.featureFlags = featureFlags
    }

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
