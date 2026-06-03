import Foundation

// FNV-1a, not Swift's Hasher: needs to be stable across launches so template
// AI output is reproducible.
enum StableHash {
    static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }

    static func index(_ string: String, modulo count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(fnv1a(string) % UInt64(count))
    }
}
