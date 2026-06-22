//
//  AnimatedMeshGradient.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//


// FILE FOR ANIMATED SKY BACKGROUND

import SwiftUI

struct BackgroundSky: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    var body: some View {
        ZStack {
            AnimatedMeshGradient()
                .opacity(colorScheme == .dark ? 0 : 1)
            DarkAnimatedMeshGradient()
                .opacity(colorScheme == .dark ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.5), value: colorScheme)
    }
}


struct AnimatedMeshGradient: View {
    private let points: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.30], [0.50, 0.30], [1.0, 0.30],
        [0.0, 0.65], [0.50, 0.65], [1.0, 0.65],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ]

    private enum Palette {
        static let deepBlue: Color = Color(hex: 0x0D47A1)
        static let blue: Color = Color(hex: 0x1565C0)
        static let blueMid: Color = Color(hex: 0x1976D2)
        static let blueBright: Color = Color(hex: 0x1E88E5)
        static let sky: Color = Color(hex: 0x29B6F6)
        static let skyBright: Color = Color(hex: 0x4FC3F7)
        static let cloudLight: Color = Color(hex: 0xE1F5FE)
        static let cloudMid: Color = Color(hex: 0xB3E5FC)
        static let white: Color = Color(hex: 0xFFFFFF)
    }

    private let colors: [Color] = [
        Palette.deepBlue, Palette.blue, Palette.deepBlue,
        Palette.blueMid, Palette.blueBright, Palette.blueMid,
        Palette.sky, Palette.skyBright, Palette.sky,
        Palette.cloudLight, Palette.white, Palette.cloudMid
    ]

    var body: some View {
        MeshGradient(width: 3, height: 4, points: points, colors: colors)
    }
}


struct DarkAnimatedMeshGradient: View {
    private let points: [SIMD2<Float>] = [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.30], [0.50, 0.30], [1.0, 0.30],
        [0.0, 0.65], [0.50, 0.65], [1.0, 0.65],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ]

    private enum Palette {
        static let indigo: Color = Color(hex: 0x1A1040)
        static let indigoLight: Color = Color(hex: 0x1E1350)
        static let violet: Color = Color(hex: 0x2D1B69)
        static let violetBright: Color = Color(hex: 0x3D2580)
        static let violetWarm: Color = Color(hex: 0x4A2080)
        static let violetDeep: Color = Color(hex: 0x3D1870)
        static let violetPink: Color = Color(hex: 0x5C2D8A)
        static let magenta: Color = Color(hex: 0x5B1F6A)
        static let magentaWarm: Color = Color(hex: 0x7B2D5E)
    }

    private let colors: [Color] = [
        Palette.indigo, Palette.indigoLight, Palette.indigo,
        Palette.violet, Palette.violetBright, Palette.violet,
        Palette.violetWarm, Palette.violetPink, Palette.violetDeep,
        Palette.magenta, Palette.magentaWarm, Palette.magenta
    ]

    var body: some View {
        ZStack {
            MeshGradient(width: 3, height: 4, points: points, colors: colors)
            StarsView()
        }
    }
}

struct StarsView: View {
    struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let animDuration: Double
    }

    private static let stars: [Star] = (0..<200).map { index in
        Star(
            id: index,
            x: CGFloat(value(for: index, key: "x", in: 0.0...1.0)),
            y: CGFloat(value(for: index, key: "y", in: 0.0...1.0)),
            size: CGFloat(value(for: index, key: "size", in: 0.8...2.5)),
            opacity: value(for: index, key: "opacity", in: 0.5...1.0),
            animDuration: value(for: index, key: "duration", in: 1.5...5.0)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Self.stars) { star in
                    StarDot(size: star.size,
                            opacity: star.opacity,
                            duration: star.animDuration)
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                }
            }
        }
    }

    private static func value(for index: Int, key: String, in range: ClosedRange<Double>) -> Double {
        let sample = Double(StableHash.fnv1a("background-star-\(index)-\(key)")) / Double(UInt64.max)
        return range.lowerBound + (sample * (range.upperBound - range.lowerBound))
    }
}

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
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: twinkle)
            .onAppear {
                twinkle = true
            }
    }
}


#Preview {
    BackgroundSky()
        .ignoresSafeArea()
}
