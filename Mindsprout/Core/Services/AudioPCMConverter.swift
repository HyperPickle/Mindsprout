import Foundation
import AVFoundation

/// Converts a recorded audio file (the app records 44.1 kHz mono `.m4a`) into the
/// 16 kHz mono 32-bit float PCM samples that whisper.cpp expects as input.
enum AudioPCMConverter {

    /// whisper.cpp operates on 16 kHz mono float samples.
    static let targetSampleRate: Double = 16_000

    enum ConversionError: Error {
        case unsupportedFormat
        case converterUnavailable
    }

    /// Reads the audio at `url` and returns interleaved-free mono samples
    /// resampled to 16 kHz. Returns an empty array when the file holds no audio.
    static func float16kMonoSamples(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let inputFormat = file.processingFormat

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw ConversionError.unsupportedFormat
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw ConversionError.converterUnavailable
        }

        let frameCount = AVAudioFrameCount(file.length)
        if frameCount == 0 { return [] }

        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFormat,
            frameCapacity: frameCount
        ) else {
            throw ConversionError.unsupportedFormat
        }
        try file.read(into: inputBuffer)

        // Size the output buffer for the resampled length (plus headroom).
        let ratio = targetSampleRate / inputFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1024
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputCapacity
        ) else {
            throw ConversionError.unsupportedFormat
        }

        var consumed = false
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if consumed {
                outStatus.pointee = .endOfStream
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if let conversionError { throw conversionError }
        guard status != .error else { throw ConversionError.converterUnavailable }

        guard let channel = outputBuffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(outputBuffer.frameLength)))
    }
}
