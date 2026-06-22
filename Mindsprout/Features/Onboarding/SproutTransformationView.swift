//
//  SproutTransformationView.swift
//  Mindsprout
//
//  Created by Changrila Souksamlane on 11/6/2026.
//

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
    
    var body: some View {
        ZStack {
            BackgroundSky()
                .ignoresSafeArea()
            
            ZStack {
                SproutIdleView()
                    .frame(width: 300, height: 300)
                    .offset(x: 0, y: -10)
            }
            
            VStack(spacing: 32) {
                Spacer()
                
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
                
                Spacer().frame(height: 20)
                
                if showButton {
                    Button {
                        hasCompletedOnboarding = true
                        isLoggedIn = true
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
            startTransformationFlow()
        }
    }
    
    func startTransformationFlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
