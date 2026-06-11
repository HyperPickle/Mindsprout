import SwiftUI
import SwiftData

struct ProfileTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appEnvironment) private var env
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Query private var sprouts: [Sprout]
    @Query private var users: [User]
    @Query private var trips: [Trip]
    @Query(filter: #Predicate<Reflection> { $0.isDraft == false }) private var reflections: [Reflection]

    @State private var showSettings = false
    @State private var isEditingName = false
    @State private var editedName = ""

    private var sprout: Sprout? { sprouts.first }
    private var user: User? { users.first }
    private var activeTrip: Trip? { TripResolver.active(in: trips) }

    private var displayName: String {
        let name = user?.displayName ?? ""
        return name.isEmpty ? "Traveler" : name
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
                                ZStack(alignment: .bottomTrailing) {
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

                                    if user?.profilePhotoPath != nil {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.black.opacity(0.6))
                                            )
                                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                                            .offset(x: 4, y: 4)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            
                            VStack(spacing: 20) {
                                Button {
                                    editedName = user?.displayName ?? ""
                                    isEditingName = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(displayName)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .buttonStyle(.plain)

                                // Location Badge (Full width) — reflects the active trip
                                HStack(spacing: Spacing.xs) {
                                    Spacer()
                                    Image(systemName: activeTrip == nil ? "map" : "mappin")
                                        .font(.system(size: 14) )
                                    Text(activeTrip.map { "\($0.destination), \($0.country)" } ?? "Planning next trip")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Spacer()
                                }
                                .padding(.vertical, Spacing.sm)
                                .liquidGlass(cornerRadius: CornerRadius.medium)
                                .padding(.horizontal, Spacing.screenEdge)

                                // XP Section (Full row style)
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.45, green: 0.84, blue: 0.48))
                                    
                                    Text("Lv. \(sprout?.level ?? 1)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))

                                    XPBar(progress: levelProgress.span > 0
                                        ? Double(levelProgress.within) / Double(levelProgress.span)
                                        : 1)
                                        .frame(height: 10)

                                    Text(levelProgress.span > 0
                                        ? "\(levelProgress.within)/\(levelProgress.span)xp"
                                        : "MAX")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .frame(width: 65, alignment: .trailing)
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .liquidGlass(cornerRadius: CornerRadius.medium)
                                .padding(.horizontal, Spacing.screenEdge)
                            }
                        }
                        .padding(.top, Spacing.xl)
                        
                        // Stats Grid
                        HStack(spacing: Spacing.md) {
                            StatCard(value: "\(trips.count)", label: trips.count == 1 ? "Adventure" : "Adventures")
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
            .alert("Edit Name", isPresented: $isEditingName) {
                TextField("Your name", text: $editedName)
                Button("Save") {
                    let trimmed = editedName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        user?.displayName = trimmed
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
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
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)

                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .fill(Color(red: 0.07, green: 0.35, blue: 0.71).opacity(0.1))

                Capsule()
                    .fill(Color(red: 0.45, green: 0.84, blue: 0.48))
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
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
        .modelContainer(for: [Sprout.self, User.self, Trip.self, Reflection.self], inMemory: true)
}
