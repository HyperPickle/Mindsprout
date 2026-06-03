//
//  Backgrounds.swift
//  Mindsprout
//
//  Reusable background treatments: warm sand (modals/reflection), sky gradient
//  (Trips), and layered grass (Home). Programmer-art gradients now; the artist
//  can supply illustrated backdrops behind the same API later.
//

import SwiftUI

/// Flat warm-cream background used by reflection and modal flows.
struct SandBackground: View {
    var body: some View {
        AppColor.sand.ignoresSafeArea()
    }
}

/// Top-to-bottom sky gradient used behind the Trips experience.
struct SkyBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppColor.skyTop, AppColor.skyBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Layered grass backdrop for the Home / Sprout screen.
struct GrassBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppColor.skyBottom, AppColor.grassTop, AppColor.grassBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview("Backgrounds") {
    VStack(spacing: 0) {
        SkyBackground().overlay(Text("Sky").font(AppFont.headline))
        GrassBackground().overlay(Text("Grass").font(AppFont.headline))
        SandBackground().overlay(Text("Sand").font(AppFont.headline))
    }
}
