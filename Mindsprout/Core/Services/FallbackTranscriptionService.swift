import Foundation

/// Tries a primary transcriber first and falls back to a secondary one when the
/// primary throws or yields nothing. Lets us run whisper.cpp as the main engine
/// with Apple's `SpeechTranscriptionService` as a safety net, without callers
/// knowing which engine produced the text.
struct FallbackTranscriptionService: Transcribing {
    let primary: any Transcribing
    let fallback: any Transcribing
    var primaryTimeoutSeconds: Duration = .seconds(15)
    var fallbackTimeoutSeconds: Duration = .seconds(20)

    func transcribe(url: URL) async throws -> String {
        do {
            let text = try await Self.withTimeout(primaryTimeoutSeconds) {
                try await primary.transcribe(url: url)
            }
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return try await Self.withTimeout(fallbackTimeoutSeconds) {
                    try await fallback.transcribe(url: url)
                }
            }
            return text
        } catch {
            // Primary failed hard; let the fallback try. If it also throws, that
            // error propagates to the existing caller error path.
            return try await Self.withTimeout(fallbackTimeoutSeconds) {
                try await fallback.transcribe(url: url)
            }
        }
    }

    private static func withTimeout<T: Sendable>(
        _ duration: Duration,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let oneShot = TimeoutContinuation(continuation)
            let operationTask = Task {
                do {
                    oneShot.resume(returning: try await operation())
                } catch {
                    oneShot.resume(throwing: error)
                }
            }
            let timeoutTask = Task {
                try? await Task.sleep(for: duration)
                operationTask.cancel()
                oneShot.resume(throwing: TranscriptionError.timedOut)
            }

            oneShot.onResume = {
                operationTask.cancel()
                timeoutTask.cancel()
            }
        }
    }
}

private final class TimeoutContinuation<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false
    private let continuation: CheckedContinuation<T, any Error>
    var onResume: (@Sendable () -> Void)?

    init(_ continuation: CheckedContinuation<T, any Error>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        guard markResumed() else { return }
        continuation.resume(returning: value)
        onResume?()
    }

    func resume(throwing error: any Error) {
        guard markResumed() else { return }
        continuation.resume(throwing: error)
        onResume?()
    }

    private func markResumed() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !didResume else { return false }
        didResume = true
        return true
    }
}
