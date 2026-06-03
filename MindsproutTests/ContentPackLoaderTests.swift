import Testing
import Foundation
@testable import Mindsprout

struct ContentPackLoaderTests {

    @Test func loadsBundledContentPack() throws {
        let pack = try ContentPackLoader(bundle: .main).load()

        #expect(!pack.prompts.inspirationPrompts.isEmpty)
        #expect(!pack.prompts.highlights(for: .solo).isEmpty)
        #expect(!pack.prompts.highlights(for: .business).isEmpty)
        #expect(!pack.expectations.presets(for: .family).isEmpty)
    }

    @Test func highlightsFallBackToDefault() throws {
        let pack = try ContentPackLoader(bundle: .main).load()
        // Every trip type resolves to a non-empty list (own or default).
        for type in TripType.allCases {
            #expect(!pack.prompts.highlights(for: type).isEmpty)
        }
    }

    @Test func missingResourceThrows() {
        // An empty bundle has no JSON → loader surfaces a clear error.
        let emptyBundle = Bundle(for: BundleMarker.self)
        let loader = ContentPackLoader(bundle: emptyBundle)
        #expect(throws: (any Error).self) {
            _ = try loader.load()
        }
    }
}

private final class BundleMarker {}
