import SwiftUI
import UIKit

enum AppThemePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { self.rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // nil = primary AppIcon, which adapts to the system appearance on its own.
    var alternateIconName: String? {
        switch self {
        case .system: return nil
        case .light: return "AppIconLight"
        case .dark: return "AppIconDark"
        }
    }
}

@MainActor
enum AppIconManager {
    static func apply(_ preference: AppThemePreference) {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons else { return }
        let target = preference.alternateIconName
        guard app.alternateIconName != target else { return }
        app.setAlternateIconName(target)
    }
}

private struct ModalScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            content
        }
        .padding(20)
        .selfSizingSheet()
    }
}

private struct SelfSizingSheet: ViewModifier {
    @State private var height: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { height = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, newValue in height = newValue }
                }
            }
            .presentationDetents(height > 0 ? [.height(height)] : [.medium])
    }
}

private extension View {
    func selfSizingSheet() -> some View { modifier(SelfSizingSheet()) }
}

struct ThemeSettingsModal: View {
    @AppStorage("appThemePreference") private var themePreference: AppThemePreference = .system

    var body: some View {
        ModalScaffold(title: "Appearance") {
            VStack(spacing: 0) {
                ForEach(AppThemePreference.allCases) { theme in
                    Button {
                        themePreference = theme
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if themePreference == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    if theme != AppThemePreference.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }
}

struct NotificationsSettingsModal: View {
    var body: some View {
        ModalScaffold(title: "Notifications") {
            VStack(spacing: 12) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Notifications Coming Soon")
                    .font(.headline)
                Text("We're working on bringing you notification settings in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct HelpSupportModal: View {
    var body: some View {
        ModalScaffold(title: "Help & Support") {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Us")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Button("Email Support") { }
                    Button("Report a Bug") { }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("FAQ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text("How do I earn XP?")
                    Text("Can I change my avatar?")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AboutSettingsModal: View {
    var body: some View {
        ModalScaffold(title: "About") {
            VStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Mindsprout")
                    .font(.largeTitle.bold())

                Text("Grow your mind, one reflection at a time.")
                    .multilineTextAlignment(.center)

                Text("© 2024 Mindsprout Inc.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}
