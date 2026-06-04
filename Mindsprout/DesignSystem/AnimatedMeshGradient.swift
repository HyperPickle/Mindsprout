//
//  AnimatedMeshGradient.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//


// FILE FOR ANIMATED SKY BACKGROUND

import SwiftUI

// CHANGE BACKGROUND ACCORDING TO LIGHT/DARK MODE
struct BackgroundSky: View{
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var body: some View {
        if colorScheme == .dark{
            DarkAnimatedMeshGradient()
        } else  {
            AnimatedMeshGradient()
        }
    }
    
}


// LIGHT MODE BACKGROUND - BLUE SKY
struct AnimatedMeshGradient: View {
    @State var appear = false
    @State private var animate = false
        
        var body: some View {
            MeshGradient(width: 3, height: 4, points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],

                // ROW 2
                [0.0, 0.30],[animate ? 0.45 : 0.55, animate ? 0.28 : 0.32], [1.0, 0.30],

                // ROW 3
                [0.0, 0.65],[animate ? 0.55 : 0.45, animate ? 0.68 : 0.62],[1.0, 0.65],

                // ROW 4
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ], colors: [
                //DARKER BLUE COLOR
                Color(hex: "0D47A1"), Color(hex: "1565C0"), Color(hex: "0D47A1"),

                // BLUE COLOR
                Color(hex: "1976D2"), Color(hex: "1E88E5"), Color(hex: "1976D2"),

                // SKY BLUE COLOR
                Color(hex: "29B6F6"), animate ? Color(hex: "4FC3F7") : Color(hex: "29B6F6"), Color(hex: "29B6F6"),

                // WHITE CYAN COLOR - Cloud
                animate ? Color(hex: "E1F5FE") : Color(hex: "B3E5FC"), Color(hex: "FFFFFF"),animate ? Color(hex: "B3E5FC") : Color(hex: "E1F5FE")
                   ])
            .ignoresSafeArea()
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
        }
    }


// DARK MODE BACKGROUND - NIGHT SKY

struct DarkAnimatedMeshGradient: View{
    @State var appear = false
    @State private var animate = false
        
    var body: some View {
        ZStack{
            MeshGradient(width: 3, height: 4, points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],

                [0.0, 0.30],[animate ? 0.4 : 0.6, animate ? 0.25 : 0.35],[1.0, 0.30],

                [0.0, 0.65],[animate ? 0.6 : 0.4, animate ? 0.68 : 0.62],[1.0, 0.65],

                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ], colors: [
                
                // UP — DARK INDIGO
                Color(hex: "1A1040"), Color(hex: "1E1350"), Color(hex: "1A1040"),

                // MIDDLE UP — BLUE VIOLET
                Color(hex: "2D1B69"), animate ? Color(hex: "3D2580") : Color(hex: "2D1B69"), Color(hex: "2D1B69"),

                // MIDDLE DOWN — VIOLET MORE WARM WITH HIT OF PINK/RED ON THE BOTTOM
                animate ? Color(hex: "4A2080") : Color(hex: "3D1870"),animate ? Color(hex: "5C2D8A") : Color(hex: "4A2080"), animate ? Color(hex: "3D1870") : Color(hex: "4A2080"),

                // BOTTOM — WARM VIOLET
                Color(hex: "5B1F6A"), Color(hex: "7B2D5E"), Color(hex: "5B1F6A")
            ])
            .ignoresSafeArea()
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
            StarsView()
            
        }

    }
    
}

struct StarsView: View {
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let animDuration: Double
    }

    let stars: [Star] = (0..<200).map { _ in   // 120 → 200
        Star(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),        // toute la hauteur
            size: CGFloat.random(in: 0.8...2.5), // plus petites = plus réaliste
            opacity: Double.random(in: 0.5...1.0),
            animDuration: Double.random(in: 1.5...5.0)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                StarDot(size: star.size,
                        opacity: star.opacity,
                        duration: star.animDuration)
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// TO MAKE THE STAR ANIMATION
struct StarDot: View {
    let size: CGFloat
    let opacity: Double
    let duration: Double
    @State private var twinkle = false

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .opacity(twinkle ? opacity : opacity * 0.3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    twinkle = true
                }
            }
    }
}


#Preview {
    BackgroundSky()
        .ignoresSafeArea()
}
