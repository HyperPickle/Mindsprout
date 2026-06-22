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
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.label)
            Text(note)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    PlaceholderScreen(
        title: "Profile",
        systemImage: "person.crop.circle",
        note: "Profile design pending."
    )
}
