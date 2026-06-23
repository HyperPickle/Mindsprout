import SwiftUI
import SwiftData

struct ProfileTab: View {
    @Environment(\.appEnvironment) private var env
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Query private var sprouts: [Sprout]
    @Query private var users: [User]
    @Query private var trips: [Trip]
    @Query(filter: #Predicate<Reflection> { $0.isDraft == false }) private var reflections: [Reflection]

    @State private var showSettings = false

    private var sprout: Sprout? { sprouts.first }
    private var user: User? { User.current(in: users, userID: env.auth.state.userID) }
    private var activeTrip: Trip? { TripResolver.active(in: trips) }

    private var displayName: String {
        user?.resolvedDisplayName ?? "Traveler"
    }

    private var levelProgress: (within: Int, span: Int) {
        SproutProgressionEngine(config: env.gameConfig)
            .levelProgress(totalXP: sprout?.xp ?? 0, level: sprout?.level ?? 1)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Background
                BackgroundSky()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Section
                        VStack(spacing: 20) {
                            // Avatar — tappable, shows profile photo when set
                            Button {
                                modalCoordinator.present(.profilePhoto)
                            } label: {
                                if let path = user?.profilePhotoPath {
                                    AsyncImage(url: env.mediaStore.url(for: path)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle().fill(.white.opacity(0.6))
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "camera")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            
                            VStack(spacing: 20) {
                                Text(displayName)
                                    .font(AppFont.screenTitle)
                                    .foregroundColor(AppColor.label)

                                // Location Badge (Full width) — reflects the active trip
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: activeTrip == nil ? "map" : "mappin")
                                        .font(.system(size: 14) )
                                    Text(activeTrip.map { "\($0.destination), \($0.country)" } ?? "Planning next trip")
                                        .font(AppFont.callout)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .liquidGlass(cornerRadius: CornerRadius.medium)
                                .padding(.horizontal, Spacing.screenEdge)

                                // XP Section (Full row style) — opens expanded detail
                                Button {
                                    modalCoordinator.present(.xpDetail)
                                } label: {
                                    HStack(spacing: Spacing.sm) {
                                        Image("Points")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)

                                        Text("Lv. \(sprout?.level ?? 1)")
                                            .font(AppFont.callout)

                                        XPBar(progress: levelProgress.span > 0
                                            ? Double(levelProgress.within) / Double(levelProgress.span)
                                            : 1)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 10)
                                    }
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .liquidGlass(cornerRadius: CornerRadius.medium)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("View experience details")
                                .padding(.horizontal, Spacing.screenEdge)
                            }
                        }
                        .padding(.top, Spacing.xl)
                        
                        // Stats Grid
                        HStack(spacing: Spacing.md) {
                            StatCard(value: "\(trips.count)", label: trips.count == 1 ? "Trip" : "Trips")
                            StatCard(value: "\(reflections.count)", label: reflections.count == 1 ? "Reflection" : "Reflections")
                        }
                        .padding(.horizontal, Spacing.screenEdge)
                        
                        // Action Buttons
                        VStack(spacing: 20) {
                            ProfileActionButton(title: "Shop", icon: "bag") {
                                modalCoordinator.present(.shop)
                            }
                            ProfileActionButton(title: "Settings", icon: "gearshape") {
                                showSettings = true
                            }
                            ProfileActionButton(title: "About", icon: "questionmark.circle") {
                                modalCoordinator.present(.aboutSettings)
                            }
                        }
                        .padding(.horizontal, Spacing.screenEdge)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationBarHidden(true)
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            HStack(spacing: Spacing.xs) {
                Text(value)
                    .font(AppFont.sectionTitle)

                Text(label)
                    .font(AppFont.bodyEmphasized)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .liquidGlass(cornerRadius: CornerRadius.medium)
    }
}

private struct XPBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.08, green: 0.24, blue: 0.50).opacity(0.28))

                Capsule()
                    .fill(AppColor.currency)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * progress)))
            }
        }
    }
}

private struct ProfileActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .frame(width: 30)
                    Spacer()
                }

                Text(title)
                    .font(AppFont.button)
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .liquidGlass(cornerRadius: CornerRadius.medium)
        }
    }
}

#Preview {
    ProfileTab()
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(for: [Sprout.self, User.self, Trip.self, Reflection.self], inMemory: true)
}
