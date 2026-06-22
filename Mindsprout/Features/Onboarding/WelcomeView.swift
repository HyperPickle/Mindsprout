import SwiftUI
import SwiftData
import AuthenticationServices

struct WelcomeView: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.modelContext) private var modelContext

    @State private var authError: String?
    
    var onSignIn: ((String) -> Void)?

    var body: some View {
        ZStack {
            ZStack {
                BackgroundSky()
                GlobeView()
                    .offset(x: 0, y: 450)
            }

            VStack {
                Spacer()
                TitleView()
                    .offset(y: -75)
                Spacer()

                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    handleResult(result)
                })
                .signInWithAppleButtonStyle(.white)
                .frame(width: 260, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)

                if let authError {
                    Text(authError)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                }

                Text("Grow your Sprout, save your reflections.")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.label.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    .offset(y: -10)
            }
        }
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        let authorization: ASAuthorization
        switch result {
        case .success(let value):
            authorization = value
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            authError = "Sign in failed. Please try again."
            return
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authError = "Sign in failed. Please try again."
            return
        }

        let displayName = credential.fullName.flatMap { components -> String? in
            let formatted = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
            return formatted.isEmpty ? nil : formatted
        }
        let cachedProfile = env.auth.cachedProfile(for: credential.user)
        let resolvedDisplayName = displayName ?? cachedProfile?.displayName
        let resolvedEmail = credential.email ?? cachedProfile?.email

        env.auth.updateCachedProfile(
            for: credential.user,
            displayName: resolvedDisplayName,
            email: resolvedEmail
        )
        User.upsert(
            appleUserID: credential.user,
            displayName: resolvedDisplayName,
            email: resolvedEmail,
            in: modelContext
        )
        authError = nil
        onSignIn?(credential.user)
    }
}

struct TitleView: View {
    var body: some View {
        VStack(spacing: 8) {
            BlinkingSproutView()
                .frame(width: 228, height: 228)

            Text("mindsprout")
                .font(AppFont.display)
                .foregroundColor(AppColor.label)
                .padding(.top, -28)

            Text("see the world, to see yourself").italic()
                .font(AppFont.callout)
                .foregroundColor(AppColor.label)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BlinkingSproutView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame = 1

    // Mirrors SproutScene.playBlink: frames Sprout_blink_[1,2,3,2,1] at 0.08s/frame.
    private let blinkFrames = [1, 2, 3, 2, 1]
    private let frameDuration = 0.08

    var body: some View {
        Image("Sprout_blink_\(frame)")
            .resizable()
            .scaledToFit()
            .task {
                guard !reduceMotion else { return }
                await blinkLoop()
            }
    }

    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            for next in blinkFrames {
                frame = next
                try? await Task.sleep(for: .seconds(frameDuration))
            }
            frame = 1
        }
    }
}

#Preview {
    WelcomeView()
        .environment(\.appEnvironment, .preview)
}
