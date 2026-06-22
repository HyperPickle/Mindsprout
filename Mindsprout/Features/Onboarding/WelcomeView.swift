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
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                }

                Text("Grow your Sprout, save your reflections.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
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
        User.upsert(
            appleUserID: credential.user,
            displayName: displayName,
            email: credential.email,
            in: modelContext
        )
        authError = nil
        onSignIn?(credential.user)
    }
}

struct TitleView: View {
    var body: some View {
        VStack(spacing: 8) {
            SproutIdleView()
                .frame(width: 200, height: 200)

            Text("mindsprout")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, -28)

            Text("see the world, to see yourself").italic()
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    WelcomeView()
        .environment(\.appEnvironment, .preview)
}
