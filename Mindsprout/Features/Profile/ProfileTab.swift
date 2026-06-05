import SwiftUI
import SwiftData

struct ProfileTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sprouts: [Sprout]
    @Query private var trips: [Trip]
    @Query(filter: #Predicate<Reflection> { $0.isDraft == false }) private var reflections: [Reflection]
    
    private var sprout: Sprout? { sprouts.first }
    
    var body: some View {
        ZStack {
            // Animated Background
            BackgroundSky()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    // Header Section
                    VStack(spacing: Spacing.lg) {
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
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Text("Remi Rata")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            // Location Badge (Full width)
                            HStack(spacing: 8) {
                                Spacer()
                                Image(systemName: "mappin")
                                    .font(.system(size: 14))
                                Text("Kyoto, Japan")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 20)
                            .padding(.horizontal, Spacing.screenEdge)
                            
                            // XP Section (Full row style)
                            HStack(spacing: 12) {
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 20)
                            .padding(.horizontal, Spacing.screenEdge)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Stats Grid
                    HStack(spacing: Spacing.md) {
                        StatCard(value: "\(trips.count)", label: "Adventures\nCompleted")
                        StatCard(value: "\(reflections.count)", label: "Reflections\nCompleted")
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    
                    // Action Buttons
                    VStack(spacing: Spacing.sm) {
                        ProfileActionButton(title: "Shop", icon: "bag", color: Color(red: 0.27, green: 0.61, blue: 0.87))
                        ProfileActionButton(title: "Settings", icon: "gearshape", color: Color(red: 0.44, green: 0.70, blue: 0.90))
                        ProfileActionButton(title: "Sign Out", icon: "arrow.right.square", color: Color(red: 0.57, green: 0.78, blue: 0.93))
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, 48)
                }
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

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .liquidGlass(cornerRadius: 15)
    }
}

private struct XPBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.07, green: 0.35, blue: 0.71).opacity(0.1))
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.45, green: 0.84, blue: 0.48))
                    .frame(width: max(0, min(geo.size.width, geo.size.width * progress)))
            }
        }
    }
}

private struct ProfileActionButton: View {
    let title: String
    let icon: String
    var color: Color = Color(red: 0.27, green: 0.61, blue: 0.87)

    var body: some View {
        Button(action: {}) {
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
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .liquidGlass(cornerRadius: 15)
        }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 10) -> some View {
        self
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .foregroundStyle(Color(hex: 0x5C6A6E))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}

#Preview {
    ProfileTab()
        .modelContainer(for: [Sprout.self, Trip.self, Reflection.self], inMemory: true)
}
