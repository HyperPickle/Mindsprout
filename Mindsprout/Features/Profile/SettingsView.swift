import SwiftUI
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.appEnvironment) private var env
    @State private var showSignOutConfirm = false
    @State private var showPrivacyPolicy = false
    @State private var showRenameSprout = false
    @State private var newSproutName = ""
    @AppStorage("sproutName") private var savedSproutName = ""

    var body: some View {
        ZStack {
            // Animated Background
            BackgroundSky()

            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(Spacing.sm)
                            .contentShape(Rectangle())
                    }

                    Spacer()

                    Text("Settings")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        SettingsActionButton(title: "Rename Sprout", icon: "leaf") {
                            newSproutName = savedSproutName
                            showRenameSprout = true
                        }
                        SettingsActionButton(title: "Appearance", icon: "eye") {
                            modalCoordinator.present(.themeSettings)
                        }
                        SettingsActionButton(title: "Privacy Policy", icon: "lock.shield") {
                            showPrivacyPolicy = true
                        }
                        
                        SettingsActionButton(title: "Sign Out", icon: "arrow.right.square") {
                            showSignOutConfirm = true
                        }

                        Text("Version 1.0.0")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColor.onBackground)
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacyPolicy) {
            if let url = URL(string: "https://mindsprout-website.vercel.app/privacy.html") {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .alert("Rename Sprout", isPresented: $showRenameSprout) {
            TextField("Sprout's name", text: $newSproutName)
            Button("Save") {
                let trimmed = newSproutName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { savedSproutName = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                env.auth.signOut()
            }
        } message: {
            Text("You can sign back in anytime. Your trips and Sprout stay safe on this device.")
        }
    }
}

private struct SettingsActionButton: View {
    let title: String
    let icon: String
    var action: () -> Void = {}
    
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

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    SettingsView()
}
