import SwiftUI
import SwiftData

struct ProfileTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sprouts: [Sprout]
    @Query private var trips: [Trip]
    @Query(filter: #Predicate<Reflection> { $0.isDraft == false }) private var reflections: [Reflection]
    
    @State private var showSettings = false
    
    private var sprout: Sprout? { sprouts.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Background
                BackgroundSky()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Section
                        VStack(spacing: 20) {
                            // Avatar (Solid white circle with camera icon)
                            Circle()
                                .fill(.white)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.4))
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            
                            VStack(spacing: 20) {
                                HStack(spacing: Spacing.xs) {
                                    Text("Remi Rata")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "pencil")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                
                                // Location Badge (Full width)
                                HStack(spacing: Spacing.xs) {
                                    Spacer()
                                    Image(systemName: "mappin")
                                        .font(.system(size: 14) )
                                    Text("Kyoto, Japan")
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
                                    
                                    XPBar(progress: Double(sprout?.xp ?? 200) / 1000.0)
                                        .frame(height: 10)
                                    
                                    Text("\(sprout?.xp ?? 200)/1000xp")
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
                            StatCard(value: "\(trips.count)", label: "Adventures\nCompleted")
                            StatCard(value: "\(reflections.count)", label: "Reflections\nCompleted")
                        }
                        .padding(.horizontal, Spacing.screenEdge)
                        
                        // Action Buttons
                        VStack(spacing: 20) {
                            ProfileActionButton(title: "Shop", icon: "bag") {
                                // Shop action
                            }
                            ProfileActionButton(title: "Settings", icon: "gearshape") {
                                showSettings = true
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
        .modelContainer(for: [Sprout.self, Trip.self, Reflection.self], inMemory: true)
}
