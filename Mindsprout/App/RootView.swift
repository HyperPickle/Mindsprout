import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    @Environment(\.appEnvironment) private var env
    @State private var selection: AppTab = .home
    @State private var modalCoordinator = ModalCoordinator()

    let featureFlags: FeatureFlags

    init(featureFlags: FeatureFlags = .default) {
        self.featureFlags = featureFlags
    }

    var body: some View {
        Group {
            if !isLoggedIn {
                authFlow
            } else {
                appShell
            }
        }
        .animation(.spring(duration: 0.5), value: isLoggedIn)
        .task {
            if isLoggedIn {
                await env.auth.revalidate()
            }
        }
    }

    private var authFlow: some View {
        OnboardingCoordinatorView()
            .transition(.opacity)
    }

    private var appShell: some View {
        @Bindable var coordinator = modalCoordinator

        return TabView(selection: $selection) {
            Tab(AppTab.adventures.title, systemImage: AppTab.adventures.systemImage, value: AppTab.adventures) {
                AdventuresTab()
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(AppTab.reflect.title, systemImage: AppTab.reflect.systemImage, value: AppTab.reflect) {
                ReflectTab(selection: $selection)
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeTab(selection: $selection)
                    .toolbar(.hidden, for: .tabBar)
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileTab()
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .tint(AppColor.primary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $selection)
        }
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
