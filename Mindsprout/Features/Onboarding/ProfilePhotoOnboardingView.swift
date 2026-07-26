import SwiftUI
import SwiftData

struct ProfilePhotoOnboardingView: View {
    @Query private var users: [User]

    let userID: String?
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
                        .foregroundStyle(AppColor.label)

                    Text("Show off your travel self.")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                }

                ProfilePhotoEditorContent(style: .onboarding, userID: userID)
                
                Spacer()
                
                Button("Continue") {
                    onComplete()
                }
                .buttonStyle(.primaryWhiteSentenceCase)
                .frame(width: 320)
                .opacity(user?.profilePhotoPath == nil ? 0.6 : 1.0)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ProfilePhotoOnboardingView(userID: nil, onComplete: {})
        .environment(\.appEnvironment, .preview)
}
