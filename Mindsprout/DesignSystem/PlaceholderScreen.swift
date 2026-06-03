import SwiftUI

struct PlaceholderScreen: View {
    let title: LocalizedStringKey
    let systemImage: String
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
