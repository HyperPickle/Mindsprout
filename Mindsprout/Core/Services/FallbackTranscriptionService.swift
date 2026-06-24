import Foundation

/// Tries a primary transcriber first and falls back to a secondary one when the
/// primary throws or yields nothing. Lets us run whisper.cpp as the main engine
/// with Apple's `SpeechTranscriptionService` as a safety net, without callers
/// knowing which engine produced the text.
struct FallbackTranscriptionService: Transcribing {
    let primary: any Transcribing
    let fallback: any Transcribing

    func transcribe(url: URL) async throws -> String {
        do {
            let text = try await primary.transcribe(url: url)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return try await fallback.transcribe(url: url)
            }
            return text
        } catch {
            // Primary failed hard; let the fallback try. If it also throws, that
            // error propagates to the existing caller error path.
            return try await fallback.transcribe(url: url)
        }
    }
}
