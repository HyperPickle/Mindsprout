import SwiftUI
import SwiftData
import AVFoundation

struct EntryStep: View {
    @Bindable var vm: ReflectionViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.md) {
                sproutHeader
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
        .background(AppColor.sand.ignoresSafeArea())
    }

    private var sproutHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button { vm.step = 1 } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(AppFont.callout)
                .foregroundStyle(AppColor.inkSecondary)
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppColor.primary.opacity(0.12)))
                Text(vm.affirmationHeadline)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
    }

    private var typeRecordToggle: some View {
        HStack(spacing: 2) {
            toggleSegment("Type", kind: .text)
            toggleSegment("Record", kind: .audio)
        }
        .padding(3)
        .background(Capsule().fill(AppColor.ink.opacity(0.08)))
    }

    private func toggleSegment(_ label: String, kind: ReflectionBodyKind) -> some View {
        Button {
            vm.bodyKind = kind
        } label: {
            Text(label)
                .font(AppFont.callout)
                .foregroundStyle(vm.bodyKind == kind ? .white : AppColor.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule().fill(vm.bodyKind == kind ? AppColor.ink : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: vm.bodyKind)
    }

    private var continueButton: some View {
        Button("Continue") {
            vm.step = 3
        }
        .buttonStyle(.primary)
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
                        .font(.system(size: 15).italic())
                        .foregroundStyle(AppColor.inkMuted)
                        .padding(Spacing.sm)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $vm.entryText)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
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
                Button {
                    vm.nextInspiration()
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "feather")
                            .font(AppFont.callout)
                        Text("Inspiration")
                            .font(AppFont.callout)
                    }
                    .foregroundStyle(AppColor.inkSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Capsule().fill(AppColor.hairline.opacity(0.4)))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("\(vm.entryText.count)/\(maxChars)")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.inkMuted)
            }
            .padding(Spacing.sm)
        }
        .background(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(.white))
        .shadow(color: AppColor.ink.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - Record Entry

private struct RecordEntryCard: View {
    @Bindable var vm: ReflectionViewModel
    @State private var recorder: AudioRecorderController = AudioRecorderController()

    var body: some View {
        VStack(spacing: Spacing.md) {
            WaveformView(amplitudes: recorder.amplitudes, isRecording: recorder.isRecording)
                .frame(height: 80)

            Text(recorder.elapsedString)
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundStyle(AppColor.ink)

            if let previewURL {
                AudioPlayerView(
                    url: previewURL,
                    configuration: .init(
                        startsWithLabeledPlayButton: true,
                        playButtonTitle: "Play Audio",
                        onReset: resetRecording
                    )
                )
                stateButton
            } else {
                VStack(spacing: Spacing.sm) {
                    stateButton
                    if recorder.uiState == .recording || recorder.uiState == .paused {
                        finishRecordingButton
                    }
                }
            }

            ReflectionTagsSection(
                tags: vm.moodTags,
                title: "Reflection Tags",
                emptyLabel: "Add tags"
            ) { updatedTags in
                vm.moodTags = updatedTags
            }
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous).fill(.white))
        .shadow(color: AppColor.ink.opacity(0.08), radius: 8, y: 4)
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
                    .font(AppFont.callout)
            }
            .foregroundStyle(stateButtonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(stateButtonBackground)
                    .shadow(color: AppColor.ink.opacity(0.12), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
        .disabled(recorder.uiState == .finished)
    }

    private var finishRecordingButton: some View {
        Button {
            Task { await stopAndSave() }
        } label: {
            Text("Finish Recording")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.ink)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Capsule().fill(AppColor.hairline.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }

    private var stateButtonTitle: LocalizedStringKey {
        switch recorder.uiState {
        case .idle:
            "Start Recording"
        case .recording:
            "Pause Recording"
        case .paused:
            "Resume Recording"
        case .finished:
            "Audio Ready"
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
            "checkmark.circle.fill"
        }
    }

    private var stateButtonForeground: Color {
        switch recorder.uiState {
        case .recording:
            .white
        default:
            AppColor.ink
        }
    }

    private var stateButtonBackground: Color {
        switch recorder.uiState {
        case .recording:
            AppColor.primary
        case .finished:
            AppColor.hairline.opacity(0.55)
        default:
            .white
        }
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
        }
    }

    private func resetRecording() {
        vm.clearAudioDraft()
        recorder.reset()
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
                    ctx.fill(path, with: .color(AppColor.primary))
                } else {
                    ctx.stroke(path, with: .color(AppColor.hairline), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                }
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
        try? AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.record()
        isRecording = true
        isPaused = false
        hasRecording = false
        uiState = .recording
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func pause() {
        recorder?.pause()
        isPaused = true
        isRecording = false
        uiState = .paused
    }

    func resume() {
        recorder?.record()
        isPaused = false
        isRecording = true
        uiState = .recording
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
        tripType: .solo,
        onDismiss: {}
    )
    vm.selectedPrompt = HighlightPrompt(id: "first-time", title: "Tried something for the first time", subtitle: "")
    return EntryStep(vm: vm)
}
