import SwiftUI
import AuthenticationServices
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var authError: String?
    
    var onContinue: ((String?) -> Void)?

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

                VStack(spacing: 12) {
                    Button("Continue on this device") {
                        User.fetchOrCreateLocal(in: modelContext)
                        authError = nil
                        onContinue?(nil)
                    }
                    .buttonStyle(.primaryWhiteSentenceCase)
                    .frame(width: 260, height: 56)

                    SignInWithAppleButton(.signIn, onRequest: { _ in
                        // Authentication is optional and needs no profile scopes.
                    }, onCompletion: { result in
                        handleResult(result)
                    })
                    .signInWithAppleButtonStyle(.white)
                    .frame(width: 260, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }

                if let authError {
                    Text(authError)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                }

                Text("Grow your Sprout, save your reflections.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.label)
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

        User.upsert(
            appleUserID: credential.user,
            displayName: nil,
            in: modelContext
        )
        authError = nil
        onContinue?(credential.user)
    }
}

struct TitleView: View {
    var body: some View {
        VStack(spacing: 0) {
            SproutView(state: .idle, idleOnly: true, draggable: false)
                .frame(width: 200, height: 200)
                .padding(.bottom, 52)

            VStack(spacing: 6) {
                Text("mindsprout")
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.label)

                Text("see the world, to see yourself").italic()
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.label)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    WelcomeView()
        .environment(\.appEnvironment, .preview)
}
