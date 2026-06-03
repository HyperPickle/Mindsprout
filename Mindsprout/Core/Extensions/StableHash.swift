//
//  StableHash.swift
//  Mindsprout
//
//  A small deterministic hash. Swift's standard `Hasher` is seeded per process
//  and is NOT stable across launches, so it can't drive reproducible template
//  output. This FNV-1a hash gives the template AI a stable, offline,
//  test-friendly way to map inputs to curated choices.
//

import Foundation

enum StableHash {
    /// 64-bit FNV-1a hash of a string's UTF-8 bytes.
    static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }

    /// A stable index into `count` choices derived from `string`.
    static func index(_ string: String, modulo count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(fnv1a(string) % UInt64(count))
    }
}
