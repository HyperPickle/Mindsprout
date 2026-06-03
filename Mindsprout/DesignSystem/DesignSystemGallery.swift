import SwiftUI

struct DesignSystemGallery: View {
    private let swatches: [(String, Color)] = [
        ("primary", AppColor.primary),
        ("primaryEdge", AppColor.primaryEdge),
        ("currency", AppColor.currency),
        ("ink", AppColor.ink),
        ("inkSecondary", AppColor.inkSecondary),
        ("sand", AppColor.sand),
        ("grassTop", AppColor.grassTop),
        ("grassBottom", AppColor.grassBottom),
        ("skyTop", AppColor.skyTop)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                section("Typography") {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Display").font(AppFont.display)
                        Text("Title").font(AppFont.title)
                        Text("Headline").font(AppFont.headline)
                        Text("Body emphasized").font(AppFont.bodyEmphasized)
                        Text("Body").font(AppFont.body)
                        Text("Callout").font(AppFont.callout)
                        Text("Caption").font(AppFont.caption)
                    }
                    .foregroundStyle(AppColor.ink)
                }

                section("Colors") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3),
                              spacing: Spacing.sm) {
                        ForEach(swatches, id: \.0) { name, color in
                            VStack(spacing: Spacing.xxs) {
                                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                    .fill(color)
                                    .frame(height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.small)
                                            .stroke(AppColor.hairline, lineWidth: 1)
                                    )
                                Text(name).font(AppFont.caption).foregroundStyle(AppColor.inkSecondary)
                            }
                        }
                    }
                }

                section("Primary button") {
                    VStack(spacing: Spacing.md) {
                        Button("Feed Sprout") {}.buttonStyle(.primary)
                        Button("Disabled") {}.buttonStyle(.primary).disabled(true)
                    }
                }

                section("Card") {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Kyoto, Japan").font(AppFont.headline).foregroundStyle(AppColor.ink)
                        Text("Wonder came slowly")
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
            }
            .padding(Spacing.screenEdge)
        }
        .background(AppColor.sand.ignoresSafeArea())
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title.uppercased())
                .font(AppFont.caption)
                .foregroundStyle(AppColor.inkMuted)
            content()
        }
    }
}

#Preview("Design System Gallery") {
    DesignSystemGallery()
}
