import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    @State private var selection: AppTab = .home
    @State private var modalCoordinator = ModalCoordinator()
    @StateObject private var navVM = NavigationViewModel()

    let featureFlags: FeatureFlags

    init(featureFlags: FeatureFlags = .default) {
        self.featureFlags = featureFlags
    }

    private var shouldShowOnboarding: Bool {
        featureFlags.onboardingEnabled && !hasCompletedOnboarding
    }

    var body: some View {
        Group {
            if !isLoggedIn {
                authFlow
            } else if shouldShowOnboarding {
                onboardingFlow
            } else {
                appShell
            }
        }
        .animation(.spring(duration: 0.5), value: isLoggedIn)
        .animation(.spring(duration: 0.5), value: navVM.showSignView)
        .animation(.spring(duration: 0.5), value: hasCompletedOnboarding)
    }

    private var authFlow: some View {
        ZStack {
            if navVM.showSignView {
                SignView()
                    .environmentObject(navVM)
                    .transition(.move(edge: .bottom))
            } else {
                WelcomeView()
                    .environmentObject(navVM)
                    .transition(.opacity)
            }
        }
    }

    private var onboardingFlow: some View {
        OnboardingView {
            hasCompletedOnboarding = true
        }
        .transition(.move(edge: .bottom))
    }

    private var appShell: some View {
        @Bindable var coordinator = modalCoordinator

        return TabView(selection: $selection) {
            Tab(AppTab.adventures.title, systemImage: AppTab.adventures.systemImage, value: AppTab.adventures) {
                AdventuresTab()
            }
            Tab(AppTab.reflect.title, systemImage: AppTab.reflect.systemImage, value: AppTab.reflect) {
                ReflectTab(selection: $selection)
            }
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeTab(selection: $selection)
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileTab()
            }
        }
        .tint(AppColor.primary)
        .environment(modalCoordinator)
        .sheet(item: $coordinator.presented) { modal in
            ModalContainer(modal: modal)
                .environment(modalCoordinator)
        }
        .transition(.opacity)
    }
}

#Preview {
    RootView()
        .environment(\.appEnvironment, .preview)
}
