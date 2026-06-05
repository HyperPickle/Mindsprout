//
//  ButtonDesignStyle.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//

import SwiftUI
import SceneKit
import WebKit

struct ButtonDesignStyle: View{
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var body: some View {
        ZStack {
            BackgroundSky()
            
                Button {
                    // Action
                } label: {
                    Text("GET STARTED")
                }
                .buttonStyle(signOtherAccountButton())
                
            }
        }
}


struct DepthButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
//    var faceColor: Color {
//        colorScheme == .dark ? Color(hex: "9488A2"): Color.white
//    }
//    
    var shadowColor: Color {
        colorScheme == .dark ? Color(hex: 0x9488A2): Color(hex:0x4CA9D0)
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color(hex: 0x7E54B8): Color(hex:0x4ECBFA)
    }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(textColor)
            .frame(width: 320, height: 30)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(shadowColor))
                        .offset(x: 0, y: 6)      // Décalage bas-droite
                
            // Face blanche principale
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .offset(y: configuration.isPressed ? 4 : 0)
                    }
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
                   
    }
    
}

struct signOtherAccountButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var iconColor: Color {
        colorScheme == .dark ? Color(hex:0x451D76): Color(hex:0x00C0FD)
    }
    
    var shadowColor: Color{
        colorScheme == .dark ? Color(hex: 0x411D63): Color(hex: 0x019BC2)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(shadowColor).opacity(0.25)
                        .offset(x: 0, y: 4)
                        .frame(width:97, height: 73, alignment: .center)
                        .blur(radius: 4)
                    RoundedRectangle(cornerRadius:12)/*.stroke(lineWidth: 2)*/
                        .foregroundStyle(Color.white)
                        .frame(width:97, height: 73, alignment: .center)
                        .offset(y: configuration.isPressed ? 4 : 0)
                }
            )
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
                   
    }
    
}

#Preview {
    ButtonDesignStyle()
}
