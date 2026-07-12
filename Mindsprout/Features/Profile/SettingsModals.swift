import SwiftUI
import UIKit
import SwiftData
import AuthenticationServices

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
    enum Style {
        case sheet
        case centered
    }

    let title: String
    var style: Style = .sheet
    var onClose: (() -> Void)? = nil
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    var body: some View {
        let scaffold = VStack(spacing: Spacing.lg) {
            HStack(spacing: 0) {
                Button { close() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColor.label)
                        .frame(width: 36, height: 36)
                }
                .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer(minLength: 0)

                Text(title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.label)

                Spacer(minLength: 0)

                Color.clear.frame(width: 36, height: 36)
            }
            content
        }
        .padding(Spacing.lg)

        switch style {
        case .sheet:
            scaffold.selfSizingSheet()
        case .centered:
            scaffold
                .frame(maxWidth: 420)
                .liquidGlass(cornerRadius: CornerRadius.large)
        }
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
                        withAnimation(.easeInOut(duration: 0.4)) {
                            themePreference = theme
                        }
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                                .font(AppFont.button)
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

struct ShopComingSoonModal: View {
    var body: some View {
        ModalScaffold(title: "Shop") {
            VStack(spacing: 12) {
                Image(systemName: "bag")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Shop Coming Soon")
                    .font(AppFont.sectionTitle)
                Text("We're working on bringing you the shop in a future update.")
                    .font(AppFont.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct AboutSettingsModal: View {
    private let heroLogoSize: CGFloat = 92
    private var heroLogoCornerRadius: CGFloat { heroLogoSize * 0.224 }

    var body: some View {
        ModalScaffold(title: "About") {
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: heroLogoSize, height: heroLogoSize)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: heroLogoCornerRadius,
                            style: .continuous
                        )
                    )

                Text("Mindsprout")
                    .font(AppFont.display)

                Text("Grow your mind, one reflection at a time.")
                    .font(AppFont.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 6) {
                    Text("Developed by")
                        .font(AppFont.eyebrow)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    VStack(spacing: 4) {
                        Text("Rishi Singhal")
                        Text("Changrila Souksamlane")
                        Text("Hiu Ying Lee (Ruby)")
                        Text("Nam Ng. (Louis)")
                        Text("Arshiya Banu Varada")
                    }
                    .font(AppFont.callout)
                }

                Text("© 2026 Mindsprout")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct AccountModal: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appEnvironment) private var env
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Query private var users: [User]

    @State private var showPhotoOptions = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showDeleteIntro = false
    @State private var showFinalDeleteConfirmation = false
    @State private var showDeletionFailed = false
    @State private var showAppleReauth = false
    @State private var isDeletingAccount = false
    @State private var didDeleteAccount = false

    private var user: User? { User.current(in: users, userID: env.auth.state.userID) }

    private var displayName: String {
        user?.resolvedDisplayName ?? "Traveler"
    }

    var body: some View {
        ModalScaffold(
            title: "Account",
            style: .centered,
            onClose: { modalCoordinator.dismiss() }
        ) {
            if didDeleteAccount {
                deletionSuccessContent
            } else if showAppleReauth {
                appleReauthContent
            } else {
                accountContent
            }
        }
        .sheet(isPresented: $showPhotoOptions) {
            ProfilePhotoModal()
        }
        .alert("Edit Name", isPresented: $isEditingName) {
            TextField("Your name", text: $editedName)
            Button("Save") {
                let trimmed = editedName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    user?.displayName = trimmed
                    if let appleUserID = user?.appleUserID, !appleUserID.isEmpty {
                        env.auth.updateCachedProfile(for: appleUserID, displayName: trimmed, email: nil)
                    }
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Account?", isPresented: $showDeleteIntro) {
            Button("Continue", role: .destructive) {
                Task { @MainActor in
                    await Task.yield()
                    showFinalDeleteConfirmation = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deleting your account removes your profile, trips, reflections, photos, audio, and Sprout progress from this device.")
        }
        .alert("This Cannot Be Undone", isPresented: $showFinalDeleteConfirmation) {
            Button("Delete Account", role: .destructive) {
                beginAccountDeletion()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your Mindsprout account data will be permanently deleted, including local media files and cached Sign in with Apple identity data.")
        }
        .alert("Account Could Not Be Deleted", isPresented: $showDeletionFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again. If this keeps happening, restart Mindsprout and delete the account again.")
        }
    }

    @ViewBuilder
    private var accountContent: some View {
        VStack(spacing: 24) {
            Button {
                showPhotoOptions = true
            } label: {
                avatar
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            VStack(spacing: 0) {
                AccountInfoRow(label: "Name", value: displayName) {
                    editedName = user?.displayName ?? ""
                    isEditingName = true
                }
            }

            Text("Click to edit.")
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(AppColor.label.opacity(0.8))
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Divider()
                    .padding(.vertical, 4)

                Button(role: .destructive) {
                    showDeleteIntro = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .font(AppFont.bodyEmphasized)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Text("Removes your local account and all saved Mindsprout data from this device.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var appleReauthContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(AppColor.label)

            Text("Confirm with Apple")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)

            Text("Apple requires a fresh sign-in before Mindsprout can revoke your Sign in with Apple credentials.")
                .font(AppFont.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SignInWithAppleButton(.continue, onRequest: { request in
                request.requestedOperation = .operationRefresh
            }, onCompletion: handleAppleReauthResult)
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .disabled(isDeletingAccount)

            if isDeletingAccount {
                ProgressView()
                    .controlSize(.small)
            }

            Button("Cancel", role: .cancel) {
                showAppleReauth = false
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount)
        }
    }

    @ViewBuilder
    private var deletionSuccessContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.green)

            Text("Account Deleted")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)

            Text("Your local Mindsprout account data has been removed from this device.")
                .font(AppFont.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                modalCoordinator.dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func beginAccountDeletion() {
        guard !isDeletingAccount else { return }
        if case .signedIn = env.auth.state {
            showAppleReauth = true
        } else {
            deleteLocalAccountAfterRevocation()
        }
    }

    private func handleAppleReauthResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let codeData = credential.authorizationCode,
                  let authorizationCode = String(data: codeData, encoding: .utf8),
                  !authorizationCode.isEmpty
            else {
                showDeletionFailed = true
                return
            }

            Task { @MainActor in
                isDeletingAccount = true
                defer { isDeletingAccount = false }
                do {
                    try await env.appleCredentialRevoker.revoke(authorizationCode: authorizationCode)
                    showAppleReauth = false
                    deleteLocalAccountAfterRevocation()
                } catch {
                    showDeletionFailed = true
                }
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            showDeletionFailed = true
        }
    }

    private func deleteLocalAccountAfterRevocation() {
        let service = AccountDeletionService(
            mediaStore: env.mediaStore,
            auth: env.auth
        )
        do {
            try service.deleteAccount(in: modelContext)
            didDeleteAccount = true
        } catch {
            showDeletionFailed = true
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let path = user?.profilePhotoPath {
            AsyncImage(url: env.mediaStore.url(for: path)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(.white.opacity(0.6))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        } else {
            Circle()
                .fill(.white)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                )
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
    }
}

private struct AccountInfoRow: View {
    let label: String
    let value: String
    var action: (() -> Void)? = nil

    @ViewBuilder
    var body: some View {
        let row = HStack {
            Text(label)
                .font(AppFont.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(AppFont.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)

        if let action {
            Button(action: action) {
                row
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            row
        }
    }
}

struct ProfilePhotoModal: View {
    var body: some View {
        ModalScaffold(title: "Profile Photo") {
            ProfilePhotoEditorContent(style: .modal, showsRemoveButton: true)
        }
    }
}
