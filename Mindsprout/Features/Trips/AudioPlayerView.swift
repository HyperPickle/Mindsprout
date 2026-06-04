import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AudioPlayerController {
    var isPlaying = false
    var progress: Double = 0
    var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(url: URL) {
        guard player == nil else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        duration = player?.duration ?? 0
    }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            if player.currentTime >= player.duration { player.currentTime = 0 }
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let controller = self else { return }
            Task { @MainActor in controller.tick() }
        }
    }

    private func tick() {
        guard let player else { return }
        duration = player.duration
        progress = player.duration > 0 ? player.currentTime / player.duration : 0
        if !player.isPlaying {
            isPlaying = false
            if progress >= 0.999 { progress = 1 }
            timer?.invalidate()
        }
    }

    func stop() {
        player?.stop()
        timer?.invalidate()
    }
}

struct AudioPlayerView: View {
    let url: URL
    @State private var controller = AudioPlayerController()

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: controller.toggle) {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppColor.cardSurface))
                    .overlay(Circle().stroke(AppColor.hairline, lineWidth: 1))
            }
            Waveform(progress: controller.progress)
                .frame(height: 28)
            Text(timeLabel)
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColor.inkSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Capsule().fill(AppColor.cardSurface.opacity(0.7)))
        .onAppear { controller.load(url: url) }
        .onDisappear { controller.stop() }
    }

    private var timeLabel: String {
        let shown = controller.isPlaying ? controller.progress * controller.duration : controller.duration
        let total = Int(shown.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct Waveform: View {
    let progress: Double
    private let heights: [CGFloat] = [6, 12, 20, 14, 24, 10, 18, 26, 16, 22, 12, 28, 14, 20, 10, 24, 16, 12, 22, 8, 18, 14, 26, 12, 20, 10, 16, 24, 14, 8]

    var body: some View {
        GeometryReader { geo in
            let count = heights.count
            let filled = Int((Double(count) * progress).rounded())
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule()
                        .fill(i < filled ? AppColor.primary : AppColor.inkMuted.opacity(0.45))
                        .frame(width: 3, height: heights[i])
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
    }
}
