//
//  SeedScene.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import RiveRuntime
import SwiftUI
import Combine

// MARK: - Controller
@MainActor
final class SeedRiveController: ObservableObject {
    let riveVM: RiveViewModel

    init() {
        // Chargement spécifique pour l'onboarding de la graine
        riveVM = RiveViewModel(
            fileName: "sprout2", // Ton fichier .riv
            stateMachineName: "SeedStateMachine",
            // .top pins the artboard's top edge to the screen top so the seed
            // travels off the real top (and the sprout descends from it) instead
            // of being clipped at the artboard boundary mid-screen. Scale is
            // unchanged, so the resting seed keeps its current size.
            alignment: .topCenter,
            artboardName: "Seed"
        )
    }

    // Déclenché uniquement lors de l'action utilisateur (validation du nom)
    func triggerWaterAnimation() {
        // Déclenche l'animation d'arrosage/transformation dans Rive
        riveVM.triggerInput("triggerWater")
    }
}

// MARK: - View
struct SeedView: View {
    @ObservedObject var controller: SeedRiveController

    var body: some View {
        ZStack {
            controller.riveVM.view()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false) // Laisse les interactions à la couche SwiftUI si besoin
        }
        .ignoresSafeArea()
    }
}

// MARK: - Exemple d'intégration (Flow Onboarding : Naming vers Transformation)
struct SeedOnboardingFlow: View {
    @State private var seedName: String = ""
    @State private var isNameConfirmed = false
    
    // On instancie le contrôleur ici
    @StateObject private var riveController = SeedRiveController()

    var body: some View {
        ZStack {
            BackgroundSky()

            // La vue Rive reçoit le contrôleur en paramètre
            SeedView(controller: riveController)

            VStack {
                Spacer()

                if !isNameConfirmed {
                    VStack(spacing: 20) {
                        TextField("Give a name", text: $seedName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)

                        Button("Confirm and water") {
                            guard !seedName.isEmpty else { return }
                            
                            UserDefaults.standard.set(seedName, forKey: "sproutName")
                            
                            withAnimation {
                                isNameConfirmed = true
                            }
                            
                            // Déclenchement de l'animation Rive
                            riveController.triggerWaterAnimation()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(seedName.isEmpty)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                } else {
                    Text("Watering of \(seedName)...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Spacer()
                    .frame(height: 50)
            }
        }
    }
}

#Preview {
    SeedOnboardingFlow()
}
