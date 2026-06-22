//
//  SproutNamingView.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import SwiftUI
import RiveRuntime

struct SproutNamingView: View {
    @State private var sproutName = ""
    @AppStorage("sproutName") var savedSproutName = ""
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    // 1. On initialise le contrôleur Rive ici pour piloter la graine
    @StateObject private var riveController = SeedRiveController()
    
    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showTransformation = false
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            BackgroundSky()
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                Spacer()
            }
            
            SeedView(controller: riveController)

            
            // ✅ Contenu centré
            VStack {
                
                
                // ✅ Seed animation (avec le contrôleur injecté en paramètre)
                
                // ✅ TextField + description
                VStack(spacing: 8) {
                    Spacer()
                    TextField("", text: $sproutName)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, design: .rounded))
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .focused($isFieldFocused)
                        .padding(.horizontal, 24)
                    
                    Text("Name little seed and press continue to see your sprout.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer().frame(height: 20)
                
                // ✅ Bouton Continue
                Button {
                    guard !sproutName.isEmpty else { return }
                    savedSproutName = sproutName
                    isFieldFocused = false
                    
                    // 1. Déclenche l'animation "triggerWater" dans Rive
                    riveController.triggerWaterAnimation()
                    
                    // 2. On attend un court instant pour laisser l'animation démarrer avant de changer d'écran
                    DispatchQueue.main.asyncAfter(deadline: .now() + 17) {
                        showTransformation = true // ✅ navigue
                        onContinue()
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Color(hex: 0x4CAF50)
                                .opacity(sproutName.isEmpty ? 0.5 : 1.0)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .disabled(sproutName.isEmpty)
                .padding(.horizontal, 24)
                .fullScreenCover(isPresented: $showTransformation) {
                    SproutTransformationView(onFinish: {}) // ✅ page de transformation
                }
                Spacer()
            }
            .frame(maxHeight: .infinity) // ✅ centré verticalement
        }
        .onTapGesture {
            isFocused = false
        }
    }
    
    @FocusState private var isFocused: Bool
}

#Preview {
    SproutNamingView(onContinue: {})
}
