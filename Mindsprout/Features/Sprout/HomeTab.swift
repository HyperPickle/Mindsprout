import SwiftUI

enum HomeRoute: Hashable {
    case dummy
}

struct HomeTab: View {
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                GrassBackground()
                VStack(spacing: Spacing.lg) {
                    Button {
                        modalCoordinator.present(.shop)
                    } label: {
                        Label("0", systemImage: "leaf.circle.fill")
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.ink)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(Capsule().fill(AppColor.cardSurface))
                    }
                    .accessibilityLabel("Open shop")

                    Spacer()

                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Home")
                            .font(AppFont.title)
                            .foregroundStyle(.white)
                        Text("Sprout, XP & Reflect-to-Feed — Phase 3 (revisable).")
                            .font(AppFont.callout)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.xl)

                    Spacer()
                }
                .padding(.top, Spacing.md)
            }
            .navigationDestination(for: HomeRoute.self) { _ in
                EmptyView()
            }
        }
    }
}

#Preview {
    HomeTab()
        .environment(ModalCoordinator())
}
