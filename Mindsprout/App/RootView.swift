import FabBar
import SwiftUI
import SwiftData
import UIKit

struct RootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    @Environment(\.appEnvironment) private var env
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: AppTab = .home
    @State private var fabBarSelection: AppTab = .home
    @State private var modalCoordinator = ModalCoordinator()

    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]

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
        TabView(selection: tabSelection) {
            Tab(AppTab.trips.title, systemImage: AppTab.trips.systemImage, value: AppTab.trips) {
                TripsTab()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab(AppTab.reflect.title, systemImage: AppTab.reflect.systemImage, value: AppTab.reflect) {
                HomeTab(selection: $selection)
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeTab(selection: $selection)
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileTab()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
            }
        }
        .fabBar(
            selection: fabSelection,
            tabs: fabBarTabs,
            action: fabAction
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var tabBarVisibility: Visibility {
        horizontalSizeClass == .compact ? .hidden : .visible
    }

    private var fabAction: FabBarAction {
        let iconTintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .white
                : UIColor(red: 4/255, green: 14/255, blue: 16/255, alpha: 1)
        }
        let presentation = RootFabRouteResolver.presentation(
            for: selection,
            reflectAction: reflectAction,
            activeTripID: activeTrip?.id
        )
        if presentation == .newTrip {
            return FabBarAction(
                systemImage: "plus",
                accessibilityLabel: "New Trip",
                tintColor: nil,
                iconTintColor: iconTintColor,
                title: selection == .trips ? "New" : "Start"
            ) { openFabAction() }
        }

        return FabBarAction(
            systemImage: AppTab.reflect.systemImage,
            accessibilityLabel: "Reflect",
            tintColor: nil,
            iconTintColor: iconTintColor,
            title: "Reflect"
        ) { openFabAction() }
    }

    private var fabBarTabs: [FabBarTab<AppTab>] {
        [
            FabBarTab(value: .trips, title: "Trips", systemImage: AppTab.trips.systemImage),
            FabBarTab(value: .home, title: "Home", systemImage: AppTab.home.systemImage),
            FabBarTab(value: .profile, title: "Profile", systemImage: AppTab.profile.systemImage),
        ]
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selection },
            set: { nextSelection in
                selection = nextSelection
                fabBarSelection = nextSelection
            }
        )
    }

    private var fabSelection: Binding<AppTab> {
        Binding(
            get: { fabBarSelection },
            set: { nextSelection in
                fabBarSelection = nextSelection
                selection = nextSelection
            }
        )
    }

    private var activeTrip: Trip? {
        TripResolver.active(in: trips)
    }

    private var reflectAction: HomeDashboardCTAAction {
        HomeDashboardState(
            hasActiveTrip: activeTrip != nil,
            completedTodayReflectionID: completedTodayReflectionID
        ).ctaAction
    }

    private var completedTodayReflectionID: UUID? {
        guard let activeTrip else { return nil }
        return todaysCompletedReflection(for: activeTrip, in: context)?.id
    }

    private func openFabAction() {
        guard let modal = RootFabRouteResolver.presentation(
            for: selection,
            reflectAction: reflectAction,
            activeTripID: activeTrip?.id
        ) else { return }

        Task { @MainActor in
            modalCoordinator.present(modal)
        }
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

enum RootFabRouteResolver {
    static func presentation(
        for selectedTab: AppTab,
        reflectAction: HomeDashboardCTAAction,
        activeTripID: UUID?
    ) -> AppModal? {
        // The FAB always offers "Reflect"; it only falls back to creating a
        // trip when none exist yet (reflectAction == .createTrip), regardless
        // of which tab is selected.
        switch reflectAction {
        case .createTrip:
            return .newTrip
        case .startReflection:
            guard let activeTripID else { return nil }
            return .reflection(tripID: activeTripID)
        case .viewTodayReflection(let reflectionID):
            return .todayReflection(reflectionID: reflectionID)
        }
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
