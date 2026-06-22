import SwiftUI
import SwiftData

struct ProfilePhotoOnboardingView: View {
    @Query private var users: [User]

    let userID: String
    var onComplete: () -> Void

    private var user: User? { User.current(in: users, userID: userID) }

    var body: some View {
        ZStack {
            BackgroundSky()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Add a Profile Photo")
                        .font(AppFont.screenTitle)
                        .foregroundColor(AppColor.label)

                    Text("Show off your travel self.")
                        .font(AppFont.callout)
                        .foregroundColor(AppColor.label.opacity(0.8))
                }

                ProfilePhotoEditorContent(style: .onboarding, userID: userID)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button("Continue") {
                        onComplete()
                    }
                    .buttonStyle(.primaryWhite)
                    .frame(width: 280)
                    .opacity(user?.profilePhotoPath == nil ? 0.6 : 1.0)
                    
                    Button("Skip for now") {
                        onComplete()
                    }
                    .font(AppFont.button)
                    .foregroundColor(AppColor.label.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ProfilePhotoOnboardingView(userID: "preview-user", onComplete: {})
        .environment(\.appEnvironment, .preview)
}
