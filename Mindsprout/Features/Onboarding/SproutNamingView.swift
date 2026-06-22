import SwiftUI
import SwiftData

struct SproutNamingView: View {
    var onBack: (() -> Void)? = nil
    var onContinue: () -> Void

    @State private var sproutName = ""
    @Environment(\.modelContext) private var context
    @Query private var sprouts: [Sprout]
    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BackgroundSky()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        if let onBack {
                            onBack()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColor.label)
                            .padding(12)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)

                Spacer()
            }

            VStack(spacing: 32) {
                SeedView()
                    .frame(width: 180, height: 180)

                VStack(spacing: 8) {
                    TextField("", text: $sproutName)
                        .multilineTextAlignment(.center)
                        .font(AppFont.callout)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .focused($isFieldFocused)
                        .padding(.horizontal, 24)

                    Text("Name your little seed and press continue to see your Sprout.")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.label)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    saveNameAndContinue()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.primaryWhite)
                .disabled(sproutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: .infinity)
        }
        .onTapGesture {
            isFieldFocused = false
        }
    }

    private func saveNameAndContinue() {
        let trimmed = sproutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = sprouts.first {
            existing.name = trimmed
        } else {
            let sprout = Sprout()
            sprout.name = trimmed
            context.insert(sprout)
        }

        try? context.save()
        isFieldFocused = false
        onContinue()
    }
}

#Preview {
    SproutNamingView(onContinue: {})
}
