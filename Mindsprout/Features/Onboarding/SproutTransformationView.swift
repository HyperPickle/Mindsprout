//
//  SproutTransformationView.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import SwiftUI
import SpriteKit

struct SproutTransformationView: View {
    @AppStorage("sproutName") var sproutName = ""
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
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
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your travel companion is ready\nto explore the world with you ")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
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
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: 0x4CAF50))
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
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
