import SwiftUI
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

    @State private var isTransforming = false
    @State private var showMeetText = false
    @State private var showStartButton = false

    private let waterAnimationDuration: Double = 17.0

    var body: some View {
        ZStack {
            BackgroundSky().ignoresSafeArea()

            SeedView(controller: riveController)

            // Top bar: x + optional Skip
            VStack {
                HStack {
                    Button {
                        if let onBack { onBack() } else { dismiss() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                    }

                    Spacer()

                    if isOnboarding && !isTransforming {
                        Button("Skip") {
                            savedSproutName = "Sprout"
                            hasCompletedOnboarding = true
                            isLoggedIn = true
                            onContinue()
                        }
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.trailing, 20)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 4)
                Spacer()
            }

            // Bottom content
            VStack {
                Spacer()

                if !isTransforming {
                    VStack(spacing: 8) {
                        TextField("", text: $sproutName)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, design: .rounded))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(Color.white.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .focused($isFieldFocused)
                            .padding(.horizontal, 24)

                        Text("Name your little seed and press continue to see your Sprout.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                    Button {
                        let trimmed = sproutName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        startFlow(name: trimmed)
                    } label: {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(hex: 0x4CAF50)
                                    .opacity(sproutName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
                    .disabled(sproutName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if showMeetText {
                    VStack(spacing: 8) {
                        Text("Meet \(savedSproutName)!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Your travel companion is ready\nto explore the world with you")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 20)

                if showStartButton {
                    Button {
                        hasCompletedOnboarding = true
                        isLoggedIn = true
                        onContinue()
                    } label: {
                        Text("Start my journey!")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: 0x4CAF50))
                            .clipShape(RoundedRectangle(cornerRadius: 30))
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
        }
        .onTapGesture {
            isFieldFocused = false
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
}

#Preview {
    SproutNamingView(onContinue: {})
}
