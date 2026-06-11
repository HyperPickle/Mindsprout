import SwiftUI

struct OnboardingCoordinatorView: View {
    enum OnboardingStep {
        case welcome
        case profilePhoto(userID: String)
    }

    @Environment(\.appEnvironment) private var env
    @State private var currentStep: OnboardingStep = .welcome

    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                WelcomeView { userID in
                    withAnimation {
                        currentStep = .profilePhoto(userID: userID)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .profilePhoto(let userID):
                ProfilePhotoOnboardingView {
                    withAnimation {
                        env.auth.handleAuthorization(userID: userID)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
}

#Preview {
    OnboardingCoordinatorView()
        .environment(\.appEnvironment, .preview)
}
