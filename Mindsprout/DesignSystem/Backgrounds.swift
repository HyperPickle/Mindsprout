import SwiftUI

struct SandBackground: View {
    var body: some View {
        Color.white.ignoresSafeArea()
    }
}

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
