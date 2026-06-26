import SwiftUI
import SwiftData
import RiveRuntime

struct SproutNamingView: View {
    // Context: onboarding (full flow) vs rename (just save + dismiss)
    var isOnboarding: Bool = true
    // Called on x button during onboarding to go back; nil = use dismiss()
    var onBack: (() -> Void)? = nil
    var onContinue: () -> Void

    @State private var sproutName = ""
    @AppStorage("sproutName") var savedSproutName = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    @StateObject private var riveController = SeedRiveController()

    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isTransforming = false
    @State private var showMeetText = false
    @State private var showStartButton = false
    @State private var keyboardHeight: CGFloat = 0

    private let waterAnimationDuration: Double = 17.0
    private var seedKeyboardOffset: CGFloat {
        guard !isTransforming else { return 0 }
        let comfortableLift = min(keyboardHeight * 0.35, 120)
        return -comfortableLift
    }

    var body: some View {
        ZStack {
            BackgroundSky().ignoresSafeArea()

            SeedView(controller: riveController)
                .offset(y: seedKeyboardOffset)
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)

            // Top bar: back button only in rename mode (no chrome during onboarding)
            if !isOnboarding {
                VStack {
                    HStack {
                        Button {
                            if let onBack { onBack() } else { dismiss() }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(AppFont.callout)
                                .foregroundStyle(AppColor.label)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect(.regular.interactive(), in: .circle)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                }
            }

            // Bottom content
            VStack {
                Spacer()

                if !isTransforming {
                    VStack(spacing: 8) {
                        TextField("", text: $sproutName)
                            .multilineTextAlignment(.center)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.label)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(Color.white.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .focused($isFieldFocused)
                            .padding(.horizontal, 24)

                        Text("Name your little seed and press continue to see your Sprout.")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.label)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                }

                if showMeetText {
                    VStack(spacing: 8) {
                        Text("Meet \(savedSproutName)!")
                            .font(AppFont.display)
                            .foregroundStyle(AppColor.label)

                        Text("Your travel companion is ready\nto explore the world with you")
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.label)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 20)

                if showStartButton {
                    Button {
                        hasCompletedOnboarding = true
                        isLoggedIn = true
                        Sprout.fetchOrCreate(name: savedSproutName, in: modelContext)
                        try? modelContext.save()
                        onContinue()
                    } label: {
                        Text("Start my journey")
                            .font(AppFont.button)
                            .foregroundStyle(AppColor.label)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.clear
                                    .readableLiquidGlass(
                                        in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: UIScreen.main.bounds.height * 0.12)
            }
            .frame(maxHeight: .infinity)
            .animation(.easeOut(duration: 0.4), value: isTransforming)
            .animation(.easeOut(duration: 0.6), value: showMeetText)
            .animation(.easeOut(duration: 0.5), value: showStartButton)

            if !isTransforming {
                VStack {
                    Spacer()

                    Button {
                        let trimmed = sproutName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        startFlow(name: trimmed)
                    } label: {
                        Text("Continue")
                            .font(AppFont.button)
                            .foregroundStyle(AppColor.label)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.clear
                                    .readableLiquidGlass(
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    )
                                    .opacity(sproutName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(sproutName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onTapGesture {
            isFieldFocused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            keyboardHeight = keyboardOverlap(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    // MARK: - Flow

    private func startFlow(name: String) {
        savedSproutName = name
        isFieldFocused = false

        if isOnboarding {
            withAnimation { isTransforming = true }
            riveController.triggerWaterAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + waterAnimationDuration) {
                withAnimation { showMeetText = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { showStartButton = true }
                }
            }
        } else {
            // Rename mode: just save and go back
            onContinue()
            dismiss()
        }
    }

    private func keyboardOverlap(from notification: Notification) -> CGFloat {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return 0
        }

        let screenHeight = UIScreen.main.bounds.height
        return max(0, screenHeight - frame.minY)
    }
}

#Preview {
    SproutNamingView(onContinue: {})
}
