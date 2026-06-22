import SwiftUI
import SwiftData
import AVFoundation

struct EntryStep: View {
    @Bindable var vm: ReflectionViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.md) {
                ReflectionStepHeader(title: vm.affirmationHeadline) {
                    vm.step = .highlight
                }
                typeRecordToggle
                if vm.bodyKind == .text {
                    TypeEntryCard(vm: vm)
                } else {
                    RecordEntryCard(vm: vm)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.md)
            continueButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var typeRecordToggle: some View {
        HStack(spacing: 2) {
            toggleSegment("Type", kind: .text)
            toggleSegment("Record", kind: .audio)
        }
        .padding(3)
        .readableLiquidGlass(in: Capsule())
    }

    private func toggleSegment(_ label: String, kind: ReflectionBodyKind) -> some View {
        Button {
            vm.bodyKind = kind
        } label: {
            Text(label)
                .font(AppFont.button)
                .foregroundStyle(vm.bodyKind == kind ? AppColor.label : AppColor.label.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule().fill(vm.bodyKind == kind ? Color.white.opacity(0.3) : Color.clear)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: vm.bodyKind)
    }

    private var continueButton: some View {
        HomeCTAButton(title: "Continue", widthScale: 1) {
            vm.step = .photos
        }
        .disabled(!vm.canContinueStep2)
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.bottom, Spacing.md)
    }
}

// MARK: - Type Entry

private struct TypeEntryCard: View {
    @Bindable var vm: ReflectionViewModel

    private let maxChars = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if vm.entryText.isEmpty {
                    Text(vm.inspirationPrompt)
                        .font(AppFont.callout.italic())
                        .foregroundStyle(ReflectionSurfaceStyle.cardTextColor.opacity(ReflectionSurfaceStyle.secondaryCardTextOpacity))
                        .padding(Spacing.sm)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $vm.entryText)
                    .font(AppFont.body)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.xs)
                    .onChange(of: vm.entryText) { _, new in
                        if new.count > maxChars {
                            vm.entryText = String(new.prefix(maxChars))
                        }
                    }
            }
            .frame(minHeight: 160)

            Divider().background(AppColor.hairline)

            HStack {
                Spacer()
                Text("\(vm.entryText.count)/\(maxChars)")
                    .font(AppFont.caption)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor.opacity(ReflectionSurfaceStyle.secondaryCardTextOpacity))
            }
            .padding(Spacing.sm)
        }
        .reflectionCardSurface(in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }
}

// MARK: - Record Entry

private struct RecordEntryCard: View {
    @Bindable var vm: ReflectionViewModel

    @Environment(\.colorScheme) private var colorScheme
    @State private var recorder: AudioRecorderController = AudioRecorderController()
    @State private var player = AudioPlayerController()

    var body: some View {
        VStack(spacing: Spacing.md) {
            if previewURL != nil {
                PlaybackWaveformView(amplitudes: player.amplitudes)
                    .frame(height: 80)
            } else {
                WaveformView(amplitudes: recorder.amplitudes, isRecording: recorder.isRecording)
                    .frame(height: 80)
            }

            if previewURL == nil {
                Text(recorder.elapsedString)
                    .font(AppFont.timerLarge)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor)
            } else {
                Text(playbackTimeLabel)
                    .font(AppFont.timerLarge)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor)
            }

            if previewURL != nil {
                playbackControls
                transcriptPreview
            } else {
                VStack(spacing: Spacing.sm) {
                    stateButton
                    if recorder.uiState == .recording || recorder.uiState == .paused {
                        recordingActionRow
                    }
                }
            }

        }
        .padding(Spacing.lg)
        .reflectionCardSurface(in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .alert("Microphone Access Required", isPresented: $recorder.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow microphone access in Settings to record audio.")
        }
        .onDisappear {
            if recorder.isRecording {
                Task { await stopAndSave() }
            }
            player.stop()
        }
        .onAppear {
            if let previewURL {
                player.load(url: previewURL)
            }
        }
        .onChange(of: vm.audioAssetID) { _, _ in
            player.reset()
            if let previewURL {
                player.load(url: previewURL)
            }
        }
    }

    private var previewURL: URL? {
        guard let assetID = vm.audioAssetID,
              let path = MediaImage.relativePath(for: assetID, in: vm.context) else { return nil }
        return vm.mediaStore.url(for: path)
    }

    private var stateButton: some View {
        Button {
            Task { await handleStateButtonTap() }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: stateButtonIcon)
                    .font(.system(size: 16, weight: .semibold))
                Text(stateButtonTitle)
                    .font(AppFont.button)
            }
            .foregroundStyle(stateButtonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .reflectionControlSurface(in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(recorder.uiState == .finished)
    }

    private var recordingActionRow: some View {
        HStack(spacing: Spacing.sm) {
            finishRecordingButton
            deleteRecordingButton
        }
    }

    private var finishRecordingButton: some View {
        Button {
            Task { await stopAndSave() }
        } label: {
            Text("Finish")
                .font(AppFont.button)
                .foregroundStyle(ReflectionSurfaceStyle.controlTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .reflectionControlSurface(in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var deleteRecordingButton: some View {
        Button(role: .destructive) {
            resetRecording()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text("Delete")
                    .font(AppFont.button)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .reflectionControlSurface(in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var playbackControls: some View {
        Button {
            player.toggle()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(player.isPlaying ? "Pause" : "Play")
                    .font(AppFont.button)
            }
            .foregroundStyle(ReflectionSurfaceStyle.controlTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .reflectionControlSurface(in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var transcriptPreview: some View {
        if vm.isTranscribing {
            HStack(spacing: Spacing.xs) {
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing…")
                    .font(AppFont.callout)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let transcript = vm.transcriptText, !transcript.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Transcript")
                    .font(AppFont.caption)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor.opacity(ReflectionSurfaceStyle.secondaryCardTextOpacity))
                Text(transcript)
                    .font(AppFont.callout)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(AppColor.hairline.opacity(0.25))
            )
        } else if let errorMessage = vm.transcriptionErrorMessage {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Transcript unavailable")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.destructive)
                Text(errorMessage)
                    .font(AppFont.callout)
                    .foregroundStyle(ReflectionSurfaceStyle.cardTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(AppColor.destructive.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(AppColor.destructive.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var stateButtonTitle: LocalizedStringKey {
        switch recorder.uiState {
        case .idle:
            "Start"
        case .recording:
            "Pause"
        case .paused:
            "Resume"
        case .finished:
            "Resume"
        }
    }

    private var stateButtonIcon: String {
        switch recorder.uiState {
        case .idle:
            "mic.fill"
        case .recording:
            "pause.fill"
        case .paused:
            "record.circle"
        case .finished:
            "record.circle"
        }
    }

    private var stateButtonForeground: Color {
        ReflectionSurfaceStyle.controlTextColor
    }

    private func handleStateButtonTap() async {
        switch recorder.uiState {
        case .idle:
            await recorder.startOrRequest()
        case .recording:
            recorder.pause()
        case .paused:
            recorder.resume()
        case .finished:
            break
        }
    }

    private func stopAndSave() async {
        if let data = await recorder.stop() {
            vm.replaceAudio(with: data)
            // Transcribe on-device in the background; ready before the user
            // finishes the flow. Result is shown in the preview below.
            Task { await vm.transcribeCurrentAudio() }
        }
    }

    private func resetRecording() {
        player.reset()
        vm.clearAudioDraft()
        recorder.reset()
    }

    private var playbackTimeLabel: String {
        let shown = player.isPlaying ? player.progress * player.duration : player.duration
        let total = Int(shown.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Waveform Canvas

private struct WaveformView: View {
    let amplitudes: [Float]
    let isRecording: Bool

    var body: some View {
        Canvas { ctx, size in
            let barCount = amplitudes.count
            guard barCount > 0 else { return }
            let barWidth: CGFloat = (size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount)
            for (i, amp) in amplitudes.enumerated() {
                let x = CGFloat(i) * (barWidth + 2)
                let barHeight = max(4, CGFloat(amp) * size.height)
                let y = (size.height - barHeight) / 2
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                if isRecording {
                    ctx.fill(path, with: .color(.white))
                } else {
                    ctx.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                }
            }
        }
    }
}

/// Live, zoomed-in playback waveform: solid white rounded bars driven by the
/// player's rolling amplitude buffer. Scrolls while playing, holds the last
/// frame when paused.
private struct PlaybackWaveformView: View {
    let amplitudes: [Float]

    var body: some View {
        Canvas { ctx, size in
            let barCount = amplitudes.count
            guard barCount > 0 else { return }
            let barWidth: CGFloat = (size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount)
            for (i, amp) in amplitudes.enumerated() {
                let x = CGFloat(i) * (barWidth + 2)
                let barHeight = max(4, CGFloat(amp) * size.height)
                let y = (size.height - barHeight) / 2
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                ctx.fill(path, with: .color(.white))
            }
        }
    }
}

// MARK: - AudioRecorderController

@Observable
@MainActor
private final class AudioRecorderController: NSObject {
    enum UIState {
        case idle
        case recording
        case paused
        case finished
    }

    var amplitudes: [Float] = Array(repeating: 0.1, count: 40)
    var isRecording = false
    var isPaused = false
    var hasRecording = false
    var showPermissionAlert = false
    var elapsedString = "00:00:00"
    var uiState: UIState = .idle

    private var recorder: AVAudioRecorder?
    private var tempURL: URL?
    private var timer: Timer?
    private var elapsed: TimeInterval = 0

    func startOrRequest() async {
        let status = AVAudioApplication.shared.recordPermission
        switch status {
        case .granted:
            startRecording()
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            if granted { startRecording() } else { showPermissionAlert = true }
        case .denied:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }

    private func startRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        tempURL = url
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        Task.detached(priority: .userInitiated) {
            try? AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            await MainActor.run {
                self.recorder = try? AVAudioRecorder(url: url, settings: settings)
                self.recorder?.isMeteringEnabled = true
                self.recorder?.record()
                self.isRecording = true
                self.isPaused = false
                self.hasRecording = false
                self.uiState = .recording
                self.elapsed = 0
                self.startTimer()
            }
        }
    }

    func pause() {
        recorder?.pause()
        timer?.invalidate()
        timer = nil
        isPaused = true
        isRecording = false
        uiState = .paused
    }

    func resume() {
        recorder?.record()
        isPaused = false
        isRecording = true
        uiState = .recording
        startTimer()
    }

    func stop() async -> Data? {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false
        isPaused = false
        try? AVAudioSession.sharedInstance().setActive(false)
        guard let url = tempURL else { return nil }
        hasRecording = true
        uiState = .finished
        return try? Data(contentsOf: url)
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        if let tempURL {
            try? FileManager.default.removeItem(at: tempURL)
        }
        tempURL = nil
        elapsed = 0
        elapsedString = "00:00:00"
        amplitudes = Array(repeating: 0.1, count: 40)
        isRecording = false
        isPaused = false
        hasRecording = false
        uiState = .idle
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func tick() {
        elapsed += 0.1
        let s = Int(elapsed)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        elapsedString = String(format: "%02d:%02d:%02d", h, m, sec)

        recorder?.updateMeters()
        let power = recorder?.averagePower(forChannel: 0) ?? -60
        let normalized = Float(max(0, min(1, (power + 60) / 60)))
        amplitudes = amplitudes.dropFirst() + [normalized]
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }
}

#Preview {
    let vm = ReflectionViewModel(
        tripID: UUID(),
        context: ModelContext(PersistenceController.makeInMemoryContainer()),
        contentPack: ContentPack(
            prompts: PromptPack(
                highlightPrompts: [:],
                inspirationPrompts: ["Let's go back to that moment.\nWhat was it?"]
            ),
            expectations: ExpectationPack(presets: [:])
        ),
        mediaStore: MediaStore(root: FileManager.default.temporaryDirectory),
        gameConfig: .default,
        ai: TemplateAIGenerationService(),
        transcriber: SpeechTranscriptionService(),
        tripType: .solo,
        onComplete: { _ in }
    )
    vm.selectedPrompt = HighlightPrompt(id: "first-time", title: "Tried something for the first time", subtitle: "")
    return EntryStep(vm: vm)
}
