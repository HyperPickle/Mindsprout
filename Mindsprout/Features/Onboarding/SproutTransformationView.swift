//
//  SproutTransformationView.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import SwiftUI
import SpriteKit
import SwiftData

struct SproutTransformationView: View {
    @Query private var sprouts: [Sprout]
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    private var sproutName: String { sprouts.first?.name ?? "" }
    @StateObject private var seedHolder = SeedSceneHolder()
    @State private var showSprout = false
    @State private var showText = false
    @State private var showButton = false
    var onFinish: () -> Void
    
    var body: some View {
        ZStack {
            // ✅ Fond
            BackgroundSky()
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // ✅ Seed/Sprout animation
                ZStack {
                    // Seed qui se transforme
                    SpriteView(scene: seedHolder.scene, options: [.allowsTransparency])
                        .frame(width: 250, height: 250)
                }
                
                // ✅ Texte qui apparaît après la transformation
                if showText {
                    VStack(spacing: 8) {
                        Text("Meet \(sproutName)!")
                            .font(AppFont.screenTitle)
                            .foregroundColor(AppColor.label)

                        Text("Your travel companion is ready\nto explore the world with you ")
                            .font(AppFont.callout)
                            .foregroundColor(AppColor.label.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                // ✅ Bouton qui apparaît après
                if showButton {
                    Button {
                        hasCompletedOnboarding = true
                        onFinish()
                    } label: {
                        Text("Start my journey!")
                    }
                    .buttonStyle(.primaryWhite)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            startTransformation()
        }
    }
    
    func startTransformation() {
        // ✅ Lance la transformation dès l'apparition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            seedHolder.scene.playSeedToSprout {
                // ✅ Texte apparaît après la transformation
                withAnimation(.easeOut(duration: 0.6)) {
                    showText = true
                }
                
                // ✅ Bouton apparaît un peu après
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showButton = true
                    }
                }
            }
        }
    }
}

#Preview {
    SproutTransformationView(onFinish:{})
}
