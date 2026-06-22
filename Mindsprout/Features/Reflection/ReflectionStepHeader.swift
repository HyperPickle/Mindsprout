import SwiftUI

struct ReflectionStepHeader: View {
    let title: String
    var backAction: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Text(title)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.xxl)

            HStack {
                if let backAction {
                    Button(action: backAction) {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.label)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .top)
    }
}
