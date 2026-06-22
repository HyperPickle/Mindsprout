import SwiftUI

struct DesignSystemGallery: View {
    private let swatches: [(String, Color)] = [
        ("primary", AppColor.primary),
        ("primaryEdge", AppColor.primaryEdge),
        ("currency", AppColor.currency),
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
                        Text("Screen title").font(AppFont.screenTitle)
                        Text("Section title").font(AppFont.sectionTitle)
                        Text("Body emphasized").font(AppFont.bodyEmphasized)
                        Text("Body").font(AppFont.body)
                        Text("Callout").font(AppFont.callout)
                        Text("Caption").font(AppFont.caption)
                        Text("EYEBROW").font(AppFont.eyebrow)
                        Text("Button").font(AppFont.button)
                        Text("12,480 XP").font(AppFont.metricLarge)
                        Text("Level 12").font(AppFont.metric)
                        Text("01:24").font(AppFont.timerLarge)
                        Text("00:38").font(AppFont.timerCompact)
                    }
                    .foregroundStyle(AppColor.label)
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
                                Text(name).font(AppFont.caption).foregroundStyle(AppColor.label)
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
                        Text("Kyoto, Japan").font(AppFont.sectionTitle).foregroundStyle(AppColor.label)
                        Text("Wonder came slowly")
                            .font(AppFont.callout)
                            .foregroundStyle(AppColor.label)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
            }
            .padding(Spacing.screenEdge)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title.uppercased())
                .font(AppFont.eyebrow)
                .foregroundStyle(AppColor.label)
            content()
        }
    }
}

#Preview("Design System Gallery — Light") {
    DesignSystemGallery()
        .preferredColorScheme(.light)
}

#Preview("Design System Gallery — Dark") {
    DesignSystemGallery()
        .preferredColorScheme(.dark)
}
