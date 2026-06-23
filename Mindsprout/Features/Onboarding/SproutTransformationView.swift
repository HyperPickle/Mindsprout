//
//  SproutTransformationView.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import SwiftUI
import RiveRuntime

struct SproutTransformationView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("sproutName") var sproutName = ""

    @StateObject private var riveController = SeedRiveController()

    @State private var showText = false
    @State private var showButton = false
    var onFinish: () -> Void

    private let waterAnimationDuration: Double = 17.0

    var body: some View {
        ZStack {
            BackgroundSky()
                .ignoresSafeArea()

            SeedView(controller: riveController)

            VStack(spacing: 32) {
                Spacer()

                if showText {
                    VStack(spacing: 8) {
                        Text("Meet \(sproutName)!")
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

                if showButton {
                    Button {
                        hasCompletedOnboarding = true
                        isLoggedIn = true
                        onFinish()
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

                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            startTransformationFlow()
        }
    }

    func startTransformationFlow() {
        // 1. Lance l'animation water dès l'apparition
        riveController.triggerWaterAnimation()

        // 2. Après la fin de l'animation → affiche le texte et le bouton
        DispatchQueue.main.asyncAfter(deadline: .now() + waterAnimationDuration) {
            withAnimation(.easeOut(duration: 0.6)) {
                showText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showButton = true
                }
            }
        }
    }
}

#Preview {
    SproutTransformationView(onFinish: {})
}
