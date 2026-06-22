import SwiftUI

struct ReflectionProgressBar: View {
    let step: ReflectionStep

    private let icons = ["mappin", "square.and.pencil", "photo", "leaf.fill"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(icons.indices, id: \.self) { index in
                stepIcon(index: index)
                if index < icons.count - 1 {
                    connector(afterIndex: index)
                }
            }
        }
        .frame(height: 32)
    }

    private func stepIcon(index: Int) -> some View {
        let active = index <= step.rawValue
        return Image(systemName: icons[index])
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(active ? AppColor.primary : AppColor.hairline)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(active ? AppColor.primary.opacity(0.12) : Color.clear)
            )
    }

    private func connector(afterIndex index: Int) -> some View {
        let filled = index + 1 <= step.rawValue
        return GeometryReader { geo in
            Path { path in
                let y = geo.size.height / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geo.size.width, y: y))
            }
            .stroke(
                filled ? AppColor.primary : AppColor.hairline,
                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
            )
        }
        .frame(height: 2)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        ReflectionProgressBar(step: .highlight)
        ReflectionProgressBar(step: .entry)
        ReflectionProgressBar(step: .photos)
        ReflectionProgressBar(step: .reward)
    }
    .padding()
    .background(Color.white)
}
