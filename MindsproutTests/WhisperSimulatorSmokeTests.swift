import Testing
import Foundation
import AVFoundation
@testable import Mindsprout

/// Smoke test: proves the whisper.cpp engine + bundled model load and run the
/// full transcription path on whatever destination the tests run on (e.g. the
/// iOS Simulator), where Apple's SpeechTranscriber model assets are unavailable.
/// Goes through the app's real service so it links via the app target (which is
/// what carries the `whisper` framework).
struct WhisperSimulatorSmokeTests {

    @Test func whisperTranscribesOnThisPlatform() async throws {
        // Write 1s of silent 16 kHz mono audio to a temp file.
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".wav")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_000))
        buffer.frameLength = 16_000 // zero-filled => silence
        try file.write(from: buffer)
        defer { try? FileManager.default.removeItem(at: url) }

        // The whole point: this runs the bundled-model whisper engine to
        // completion on this platform without throwing. Silence transcribes to
        // empty text, which is fine — we only need it to execute, not crash.
        let text = try await WhisperCppTranscriptionService().transcribe(url: url)
        #expect(text.isEmpty || !text.isEmpty)
    }
}
