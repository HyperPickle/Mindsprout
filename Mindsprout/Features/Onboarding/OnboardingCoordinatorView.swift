
import SwiftUI

struct OnboardingCoordinatorView: View {
    enum OnboardingStep {
        case welcome
        case profilePhoto(userID: String)
        case namingSprout(userID: String)
        case transformation(userID: String)
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
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .profilePhoto(let userID):
                ProfilePhotoOnboardingView {
                    withAnimation {
                        currentStep = .namingSprout(userID: userID)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .namingSprout(let userID):
                SproutNamingView(
                    isOnboarding: true,
                    onBack: {
                        withAnimation {
                            currentStep = .profilePhoto(userID: userID)
                        }
                    },
                    onContinue: {
                        withAnimation {
                            currentStep = .transformation(userID: userID)
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .transformation(let userID):
                SproutTransformationView(onFinish: {
                    withAnimation {
                        env.auth.handleAuthorization(userID: userID)
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
    }
}

#Preview {
    OnboardingCoordinatorView()
        .environment(\.appEnvironment, .preview)
}
