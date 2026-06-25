import Foundation
import whisper
import WhisperSupport

/// On-device transcription using whisper.cpp (the official XCFramework, vendored
/// through the `whisper-ios` SPM package). The default multilingual `tiny-q5_1`
/// model ships inside that package and is loaded from its resource bundle, so no
/// model/engine binaries live in the app repo. Metal acceleration is used on
/// device builds. Simulator builds force CPU because current iOS 27 simulator
/// Metal can assert inside ggml's residency-set path. Fully on-device — no
/// network, no audio leaves the device.
struct WhisperCppTranscriptionService: Transcribing {

    func transcribe(url: URL) async throws -> String {
        let samples = try AudioPCMConverter.float16kMonoSamples(from: url)
        if samples.isEmpty { return "" }

        let modelURL = WhisperModels.tinyQ5_1URL

        // whisper_full is a blocking call; run it off the cooperative pool so it
        // never stalls the main actor or Swift concurrency threads.
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try Self.runWhisper(modelURL: modelURL, samples: samples))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Runs whisper.cpp inference synchronously over 16 kHz mono float samples and
    /// returns the joined, trimmed transcript text.
    private static func runWhisper(modelURL: URL, samples: [Float]) throws -> String {
        var contextParams = whisper_context_default_params()
        #if targetEnvironment(simulator)
        contextParams.use_gpu = false
        #endif

        guard let context = modelURL.path.withCString({ path in
            whisper_init_from_file_with_params(path, contextParams)
        }) else {
            throw TranscriptionError.modelUnavailable
        }
        defer { whisper_free(context) }

        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.translate = false
        params.n_threads = Int32(Self.inferenceThreadCount)

        // "auto" lets the multilingual model detect the spoken language. The C
        // string must stay valid for the duration of whisper_full.
        let status: Int32 = "auto".withCString { language in
            params.language = language
            return samples.withUnsafeBufferPointer { buffer in
                whisper_full(context, params, buffer.baseAddress, Int32(buffer.count))
            }
        }
        guard status == 0 else { throw TranscriptionError.inferenceFailed }

        var text = ""
        for index in 0..<whisper_full_n_segments(context) {
            if let segment = whisper_full_get_segment_text(context, index) {
                text += String(cString: segment)
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static var inferenceThreadCount: Int {
        let available = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
        #if targetEnvironment(simulator)
        return min(2, available)
        #else
        return available
        #endif
    }
}
