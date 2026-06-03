//
//  ProfileTab.swift
//  Mindsprout
//
//  Profile tab — navigable placeholder. No design exists yet (Plan §2, Open
//  Question #5); intentionally empty until one lands.
//

import SwiftUI

struct ProfileTab: View {
    var body: some View {
        NavigationStack {
            // TODO: Profile design pending — build when designs land.
            PlaceholderScreen(
                title: "Profile",
                systemImage: "person.crop.circle",
                note: "Profile design pending."
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileTab()
}
