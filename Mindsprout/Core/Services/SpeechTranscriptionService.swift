import Foundation
import AVFoundation
import Speech

// The seam for turning a recorded audio file into text. The default impl is
// fully on-device and offline (SpeechTranscriptionService); a networked impl
// could replace it here without touching callers.
protocol Transcribing: Sendable {
    /// Transcribes the audio file at `url` into plain text. Returns an empty
    /// string when nothing could be transcribed. Throws on hard failures
    /// (model unavailable, unreadable audio); callers treat throw/empty as
    /// "no transcript".
    func transcribe(url: URL) async throws -> String
}

enum TranscriptionError: Error {
    case localeNotSupported
    case modelUnavailable
    case inferenceFailed
    case timedOut
}

extension TranscriptionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .localeNotSupported:
            return String(localized: "Transcription isn’t available on this device.")
        case .modelUnavailable:
            return String(localized: "The speech model couldn’t be installed. Connect to the internet and try again.")
        case .inferenceFailed:
            return String(localized: "Couldn’t transcribe this recording.")
        case .timedOut:
            return String(localized: "Transcription took too long. You can keep going without a transcript.")
        }
    }
}

/// On-device transcription using the iOS 26 Speech framework
/// (`SpeechAnalyzer` + `SpeechTranscriber`). No network is used; the language
/// model asset is downloaded once via `AssetInventory` on first use.
struct SpeechTranscriptionService: Transcribing {

    func transcribe(url: URL) async throws -> String {
        let locale = await Self.bestSupportedLocale()

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )

        try await ensureModelInstalled(for: transcriber, locale: locale)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: url)

        // Drain results concurrently while we feed the file through the analyzer.
        async let collected: String = {
            var text = AttributedString()
            for try await result in transcriber.results {
                text += result.text
            }
            return String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        }()

        if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
            try await analyzer.finalizeAndFinish(through: lastSample)
        } else {
            try await analyzer.cancelAndFinishNow()
        }

        return try await collected
    }

    // MARK: - Locale + model availability

    /// Picks the user's current locale if the transcriber supports it,
    /// otherwise the first supported locale (falling back to en-US).
    private static func bestSupportedLocale() async -> Locale {
        let supported = await SpeechTranscriber.supportedLocales
        let current = Locale.current
        if supported.contains(where: { $0.identifier(.bcp47) == current.identifier(.bcp47) }) {
            return current
        }
        return supported.first ?? Locale(identifier: "en-US")
    }

    /// Ensures the on-device model for `locale` is installed, downloading it
    /// once if necessary. Throws `.localeNotSupported` / `.modelUnavailable`
    /// when transcription cannot proceed.
    private func ensureModelInstalled(for transcriber: SpeechTranscriber, locale: Locale) async throws {
        let target = locale.identifier(.bcp47)

        let supported = await SpeechTranscriber.supportedLocales
        guard supported.contains(where: { $0.identifier(.bcp47) == target }) else {
            throw TranscriptionError.localeNotSupported
        }

        let installed = await SpeechTranscriber.installedLocales
        if installed.contains(where: { $0.identifier(.bcp47) == target }) { return }

        // Download + install the asset for this transcriber. If the system
        // can't fulfil the request (e.g. offline on first use), surface it.
        guard let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) else {
            throw TranscriptionError.modelUnavailable
        }
        try await request.downloadAndInstall()
    }
}
