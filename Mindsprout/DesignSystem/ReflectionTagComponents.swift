import SwiftUI

struct ReflectionTagChip: View {
    let text: String
    var accent: Bool = false
    var removable = false
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    chipContent
                }
                .buttonStyle(.plain)
            } else {
                chipContent
            }
        }
    }

    private var chipContent: some View {
        HStack(spacing: Spacing.xxs) {
            Text(text)
                .font(AppFont.bodyEmphasized)
            if removable {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(accent ? AppColor.label : AppColor.primaryEdge)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule().fill((accent ? AppColor.currency : AppColor.primary).opacity(0.18))
        )
        .contentShape(Capsule())
    }
}

struct ReflectionTagsSection: View {
    let tags: [String]
    var title: LocalizedStringKey = "Reflection Tags"
    var emptyLabel: LocalizedStringKey = "Add tags"
    let onSave: ([String]) -> Void

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(AppFont.eyebrow)
                    .tracking(0.8)
                    .foregroundStyle(AppColor.label)
                Spacer()
                if !tags.isEmpty {
                    Button("Edit") {
                        isEditing = true
                    }
                    .buttonStyle(.plain)
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.primaryEdge)
                }
            }

            if tags.isEmpty {
                Button {
                    isEditing = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(AppFont.callout)
                        Text(emptyLabel)
                            .font(AppFont.button)
                    }
                    .foregroundStyle(AppColor.label)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .fill(AppColor.cardSurface.opacity(0.75))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                FlowLayout(horizontalSpacing: Spacing.xs, verticalSpacing: Spacing.xs) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                        ReflectionTagChip(text: tag, accent: index.isMultiple(of: 2)) {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ReflectionTagEditorSheet(initialTags: tags) { updatedTags in
                onSave(updatedTags)
            }
        }
    }
}

struct ReflectionTagEditorSheet: View {
    let initialTags: [String]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftTags: [String]
    @State private var newTag = ""

    init(initialTags: [String], onSave: @escaping ([String]) -> Void) {
        self.initialTags = initialTags
        self.onSave = onSave
        _draftTags = State(initialValue: initialTags)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Add or refine the tags for this reflection.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.label)

                HStack(spacing: Spacing.sm) {
                    TextField("New tag", text: $newTag)
                        .textInputAutocapitalization(.words)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.label)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                .fill(AppColor.cardSurface)
                        )

                    Button("Add") {
                        addTag()
                    }
                    .buttonStyle(.primary)
                    .disabled(normalizedTag(newTag) == nil)
                }

                if draftTags.isEmpty {
                    Text("No tags yet.")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.label)
                        .padding(.vertical, Spacing.sm)
                } else {
                    FlowLayout(horizontalSpacing: Spacing.xs, verticalSpacing: Spacing.xs) {
                        ForEach(Array(draftTags.enumerated()), id: \.offset) { index, tag in
                            ReflectionTagChip(
                                text: tag,
                                accent: index.isMultiple(of: 2),
                                removable: true
                            ) {
                                draftTags.removeAll { $0 == tag }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(Spacing.screenEdge)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Edit Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draftTags)
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTag() {
        guard let tag = normalizedTag(newTag) else { return }
        draftTags.append(tag)
        newTag = ""
    }

    private func normalizedTag(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !draftTags.contains(where: { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }) else {
            return nil
        }
        return trimmed
    }
}

private struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else {
            let width = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
            let height = subviews.reduce(CGFloat.zero) { partial, subview in
                partial + subview.sizeThatFits(.unspecified).height + verticalSpacing
            }
            return CGSize(width: width, height: max(0, height - verticalSpacing))
        }

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth, lineWidth > 0 {
                totalHeight += lineHeight + verticalSpacing
                lineWidth = 0
                lineHeight = 0
            }

            lineWidth += size.width + (lineWidth > 0 ? horizontalSpacing : 0)
            lineHeight = max(lineHeight, size.height)
        }

        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = CGPoint(x: bounds.minX, y: bounds.minY)
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if point.x + size.width > bounds.maxX, point.x > bounds.minX {
                point.x = bounds.minX
                point.y += lineHeight + verticalSpacing
                lineHeight = 0
            }

            subview.place(at: point, proposal: ProposedViewSize(size))
            point.x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
