//
//  SproutNamingView.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

import SwiftUI
import SpriteKit
import SwiftData

struct SproutNamingView: View {
    @State private var sproutName = ""
    @Environment(\.modelContext) private var context
    @Query private var sprouts: [Sprout]
    @StateObject private var seedHolder = SeedSceneHolder()
    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showTransformation = false
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // ✅ Fond gradient bleu
            BackgroundSky()
            .ignoresSafeArea()
            
            // ✅ X en haut à gauche
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColor.label)
                            .padding(12)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                Spacer()
            }
            
            // ✅ Contenu centré
            VStack(spacing: 32) {
                
                // ✅ Seed animation
                SeedView()
                       .frame(width: 180, height: 180)
                
                // ✅ TextField + description
                VStack(spacing: 8) {
                    TextField("", text: $sproutName)
                        .multilineTextAlignment(.center)
                        .font(AppFont.callout)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .focused($isFieldFocused)
                        .padding(.horizontal, 24)
                    
                    Text("Name little seed and press continue to see your sprout.")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // ✅ Bouton Continue
                Button {
                    guard !sproutName.isEmpty else { return }
                    if let existing = sprouts.first {
                        existing.name = sproutName
                    } else {
                        let sprout = Sprout()
                        sprout.name = sproutName
                        context.insert(sprout)
                    }
                    try? context.save()
                    isFieldFocused = false
                    showTransformation = true  // ✅ navigue
                    onContinue()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.primaryWhite)
                .disabled(sproutName.isEmpty)
                .padding(.horizontal, 24)
                .fullScreenCover(isPresented: $showTransformation) {
                    SproutTransformationView(onFinish:{})  // ✅ page de transformation
                }
            }
            .frame(maxHeight: .infinity)  // ✅ centré verticalement
        }
        .onTapGesture {
            isFieldFocused = false
        }
    }
}

#Preview {
    SproutNamingView(onContinue:{})
}
