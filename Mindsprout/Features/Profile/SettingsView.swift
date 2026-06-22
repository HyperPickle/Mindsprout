import SwiftUI
import SafariServices
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.appEnvironment) private var env
    @Query private var sprouts: [Sprout]
    @State private var showSignOutConfirm = false
    @State private var showPrivacyPolicy = false
    @State private var showRenameSprout = false
    @State private var newSproutName = ""
    @AppStorage("sproutName") private var savedSproutName = ""

    private var sproutName: String { sprouts.first?.name.isEmpty == false ? sprouts.first!.name : "Sprout" }

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
                            .foregroundColor(AppColor.label)
                            .padding(Spacing.sm)
                            .contentShape(Rectangle())
                    }

                    Spacer()

                    Text("Settings")
                        .font(AppFont.sectionTitle)
                        .foregroundColor(AppColor.label)

                    Spacer()

                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        SettingsActionButton(title: "Account", icon: "person.crop.circle") {
                            modalCoordinator.present(.account)
                        }
                        SettingsActionButton(title: "Rename Sprout", icon: "leaf") {
                            newSproutName = sproutName
                            showRenameSprout = true
                        }
                        SettingsActionButton(title: "Appearance", icon: "eye") {
                            modalCoordinator.present(.themeSettings)
                        }
                        SettingsActionButton(title: "Privacy Policy", icon: "lock") {
                            showPrivacyPolicy = true
                        }

                        SettingsActionButton(title: "Sign Out", icon: "arrow.right.square") {
                            showSignOutConfirm = true
                        }

                        Text("Version 1.0.0")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.label)
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
                saveSproutName()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                env.auth.signOut()
            }
        } message: {
            Text("You can sign back in anytime. Your trips and \(sproutName) stay safe on this device.")
        }
    }

    private func saveSproutName() {
        let trimmed = newSproutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        savedSproutName = trimmed

        if let sprout = sprouts.first {
            sprout.name = trimmed
        } else {
            let sprout = Sprout()
            sprout.name = trimmed
            modelContext.insert(sprout)
        }

        try? modelContext.save()
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
                    .font(AppFont.button)
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
