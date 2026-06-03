//
//  PlaceholderScreen.swift
//  Mindsprout
//
//  A consistent "design pending / built in a later phase" placeholder. Used by
//  the navigable-but-undesigned destinations (Profile, Shop, Onboarding) and by
//  Phase 0 tab stubs whose real UI arrives in later phases.
//

import SwiftUI

struct PlaceholderScreen: View {
    let title: LocalizedStringKey
    let systemImage: String
    /// Short note on what lands here and when (e.g. "Trips — Phase 1").
    let note: LocalizedStringKey

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(AppColor.primary)
            Text(title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
            Text(note)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.sand.ignoresSafeArea())
    }
}

#Preview {
    PlaceholderScreen(
        title: "Profile",
        systemImage: "person.crop.circle",
        note: "Profile design pending."
    )
}
