import UIKit

// Generates deterministic placeholder photo/audio files for seeded sample
// content. Real media arrives with Reflection capture (Phase 2).
enum PlaceholderMedia {
    static func photoPNG(seed: Int, symbol: String, size: CGFloat = 900) -> Data {
        let top = color(hue: hue(seed), saturation: 0.55, brightness: 0.92)
        let bottom = color(hue: hue(seed) + 0.06, saturation: 0.75, brightness: 0.62)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
            cg.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size, y: size),
                options: []
            )
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.32, weight: .semibold)
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal) {
                let origin = CGPoint(x: (size - glyph.size.width) / 2, y: (size - glyph.size.height) / 2)
                glyph.draw(at: origin)
            }
        }
        return image.pngData() ?? Data()
    }

    // A short, soft sine tone as a 16-bit PCM WAV — enough to exercise playback.
    static func toneWAV(seconds: Double = 6, frequency: Double = 320, sampleRate: Int = 22_050) -> Data {
        let frameCount = Int(Double(sampleRate) * seconds)
        var samples = Data(capacity: frameCount * 2)
        for frame in 0..<frameCount {
            let t = Double(frame) / Double(sampleRate)
            let envelope = 0.25 * (1 - cos(2 * .pi * min(t, seconds - t) / 0.4)).clamped()
            let value = sin(2 * .pi * frequency * t) * envelope
            let scaled = Int16(max(-1, min(1, value)) * Double(Int16.max))
            withUnsafeBytes(of: scaled.littleEndian) { samples.append(contentsOf: $0) }
        }
        return wavContainer(pcm: samples, sampleRate: sampleRate)
    }

    private static func wavContainer(pcm: Data, sampleRate: Int) -> Data {
        let channels = 1, bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        var data = Data()
        func ascii(_ s: String) { data.append(s.data(using: .ascii)!) }
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        ascii("RIFF"); u32(UInt32(36 + pcm.count)); ascii("WAVE")
        ascii("fmt "); u32(16); u16(1); u16(UInt16(channels))
        u32(UInt32(sampleRate)); u32(UInt32(byteRate)); u16(UInt16(blockAlign)); u16(UInt16(bitsPerSample))
        ascii("data"); u32(UInt32(pcm.count)); data.append(pcm)
        return data
    }

    private static func hue(_ seed: Int) -> Double { (Double(seed) * 0.137).truncatingRemainder(dividingBy: 1) }

    private static func color(hue: Double, saturation: Double, brightness: Double) -> UIColor {
        UIColor(hue: CGFloat(hue.truncatingRemainder(dividingBy: 1)), saturation: saturation, brightness: brightness, alpha: 1)
    }
}

private extension Double {
    func clamped() -> Double { Swift.max(0, Swift.min(1, self)) }
}
