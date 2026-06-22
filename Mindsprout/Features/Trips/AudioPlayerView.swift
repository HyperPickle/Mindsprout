import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AudioPlayerController {
    var isPlaying = false
    var progress: Double = 0
    var duration: TimeInterval = 0
    var hasStartedPlayback = false
    /// Rolling buffer of recent playback amplitudes (0...1) for a live waveform.
    var amplitudes: [Float] = Array(repeating: 0.06, count: 40)
    /// Compact waveform summary of the saved recording for static playback UI.
    var waveformSamples: [Float] = Array(repeating: 0.12, count: 40)

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(url: URL) {
        guard player == nil else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.isMeteringEnabled = true
        player?.prepareToPlay()
        duration = player?.duration ?? 0

        Task.detached(priority: .userInitiated) { [url] in
            let samples = WaveformSampler.extractWaveformSamples(from: url, sampleCount: 40)
            await MainActor.run {
                self.waveformSamples = samples
            }
        }
    }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            Task.detached(priority: .userInitiated) {
                try? AVAudioSession.sharedInstance().setCategory(.playback)
                try? AVAudioSession.sharedInstance().setActive(true)
                await MainActor.run {
                    if player.currentTime >= player.duration { player.currentTime = 0 }
                    player.play()
                    self.isPlaying = true
                    self.hasStartedPlayback = true
                    self.startTimer()
                }
            }
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
        player.updateMeters()
        let power = player.averagePower(forChannel: 0)
        let normalized = Float(max(0, min(1, (power + 60) / 60)))
        amplitudes = Array(amplitudes.dropFirst()) + [normalized]
        if !player.isPlaying {
            isPlaying = false
            if progress >= 0.999 { progress = 1 }
            timer?.invalidate()
        }
    }

    func stop() {
        player?.stop()
        timer?.invalidate()
        isPlaying = false
        deactivateAudioSession()
    }

    func reset() {
        player?.stop()
        player = nil
        timer?.invalidate()
        isPlaying = false
        progress = 0
        hasStartedPlayback = false
        duration = 0
        amplitudes = Array(repeating: 0.06, count: 40)
        waveformSamples = Array(repeating: 0.12, count: 40)
        deactivateAudioSession()
    }

    private func deactivateAudioSession() {
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}

struct AudioPlayerView: View {
    struct Configuration {
        var startsWithLabeledPlayButton = false
        var playButtonTitle: LocalizedStringKey = "Play Audio"
        var onReset: (() -> Void)?

        static let `default` = Configuration()
    }

    let url: URL
    var configuration: Configuration = .default
    @State private var controller = AudioPlayerController()

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if configuration.startsWithLabeledPlayButton && !controller.hasStartedPlayback {
                labelledPlayButton
            } else {
                compactPlayer
            }

            if let onReset = configuration.onReset {
                Spacer(minLength: 0)
                resetButton(action: onReset)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .onAppear { controller.load(url: url) }
        .onDisappear { controller.stop() }
    }

    private var compactPlayer: some View {
        HStack(spacing: Spacing.xs) {
            Button(action: controller.toggle) {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 38, height: 38)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .readableLiquidGlass(in: Circle())

            Waveform(samples: controller.waveformSamples, progress: controller.progress)
                .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)

            Text(timeLabel)
                .frame(height: 28)
                .font(AppFont.metric)
                .foregroundStyle(AppColor.label)
        }
    }

    private var labelledPlayButton: some View {
        Button(action: controller.toggle) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(configuration.playButtonTitle)
                    .font(AppFont.button)
            }
            .foregroundStyle(AppColor.label)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .readableLiquidGlass(in: Capsule())
    }

    private func resetButton(action: @escaping () -> Void) -> some View {
        Button {
            controller.reset()
            action()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.label)
                .frame(width: 38, height: 38)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .readableLiquidGlass(in: Circle())
    }

    private var timeLabel: String {
        let shown = controller.isPlaying ? controller.progress * controller.duration : controller.duration
        let total = Int(shown.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct Waveform: View {
    let samples: [Float]
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let count = samples.count
            let filled = Int((Double(count) * progress).rounded())
            let barWidth: CGFloat = 3
            let totalBarWidth = CGFloat(count) * barWidth
            let spacing = count > 1 ? max(0, (geo.size.width - totalBarWidth) / CGFloat(count - 1)) : 0

            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule()
                        .fill(i < filled ? AppColor.label : AppColor.label.opacity(0.28))
                        .frame(
                            width: barWidth,
                            height: max(4, min(geo.size.height, CGFloat(samples[i]) * geo.size.height))
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private enum WaveformSampler {
    nonisolated static func extractWaveformSamples(from url: URL, sampleCount: Int) -> [Float] {
        guard sampleCount > 0 else { return [] }

        do {
            let sourceFile = try AVAudioFile(forReading: url)
            guard
                let format = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: sourceFile.processingFormat.sampleRate,
                    channels: sourceFile.processingFormat.channelCount,
                    interleaved: false
                ),
                let buffer = AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: AVAudioFrameCount(sourceFile.length)
                )
            else {
                return Array(repeating: 0.12, count: sampleCount)
            }

            try sourceFile.read(into: buffer)

            let frameLength = Int(buffer.frameLength)
            let channelCount = Int(buffer.format.channelCount)
            guard
                frameLength > 0,
                channelCount > 0,
                let channelData = buffer.floatChannelData
            else {
                return Array(repeating: 0.12, count: sampleCount)
            }

            let framesPerBucket = max(1, frameLength / sampleCount)
            var peaks = Array(repeating: Float(0), count: sampleCount)

            for bucket in 0..<sampleCount {
                let start = bucket * framesPerBucket
                let end = min(frameLength, start + framesPerBucket)
                guard start < end else { continue }

                var bucketPeak: Float = 0
                for channel in 0..<channelCount {
                    let samples = channelData[channel]
                    for frame in start..<end {
                        bucketPeak = max(bucketPeak, abs(samples[frame]))
                    }
                }
                peaks[bucket] = bucketPeak
            }

            let maxPeak = peaks.max() ?? 0
            guard maxPeak > 0 else { return Array(repeating: 0.12, count: sampleCount) }

            return peaks.map { max(0.12, min(1, $0 / maxPeak)) }
        } catch {
            return Array(repeating: 0.12, count: sampleCount)
        }
    }
}
