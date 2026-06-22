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
            Tab(AppTab.trips.title, systemImage: AppTab.trips.systemImage, value: AppTab.trips) {
                TripsTab()
            }
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeTab()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileTab()
            }
        }
        .tint(AppColor.label)
        .environment(modalCoordinator)
        .sheet(item: bottomSheetBinding) { modal in
            ModalContainer(modal: modal)
                .environment(modalCoordinator)
        }
        .fullScreenCover(item: fullScreenCoverBinding, onDismiss: {
            modalCoordinator.presentPendingLevelUpIfNeeded()
        }) { modal in
            ModalContainer(modal: modal)
                .environment(modalCoordinator)
        }
        .overlay {
            CenteredModalHost(coordinator: modalCoordinator)
        }
        .transition(.opacity)
    }

    /// Drives the standard bottom sheet for every modal except the ones that
    /// prefer a centered pop-in (handled by `CenteredModalHost`) or a
    /// full-screen cover (handled separately below).
    private var bottomSheetBinding: Binding<AppModal?> {
        Binding(
            get: {
                guard let modal = modalCoordinator.presented,
                      !modal.prefersCenteredPresentation,
                      !modal.prefersFullScreenCover else { return nil }
                return modal
            },
            set: { modalCoordinator.presented = $0 }
        )
    }

    /// Drives the full-screen cover for modals that present edge-to-edge.
    private var fullScreenCoverBinding: Binding<AppModal?> {
        Binding(
            get: {
                guard let modal = modalCoordinator.presented,
                      modal.prefersFullScreenCover else { return nil }
                return modal
            },
            set: { modalCoordinator.presented = $0 }
        )
    }
}

/// Renders centered modals as a dimmed backdrop with a scale/fade pop-in,
/// instead of the system bottom sheet.
private struct CenteredModalHost: View {
    @Bindable var coordinator: ModalCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var centeredModal: AppModal? {
        guard let modal = coordinator.presented,
              modal.prefersCenteredPresentation else { return nil }
        return modal
    }

    var body: some View {
        ZStack {
            if let modal = centeredModal {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture { coordinator.dismiss() }

                ModalContainer(modal: modal)
                    .environment(coordinator)
                    .padding(.horizontal, Spacing.lg)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.85),
            value: coordinator.presented
        )
    }
}

#Preview {
    RootView()
        .environment(\.appEnvironment, .preview)
}
