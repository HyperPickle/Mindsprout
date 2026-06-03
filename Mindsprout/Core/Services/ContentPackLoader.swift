import Foundation

protocol ContentPackProviding: Sendable {
    func load() throws -> ContentPack
}

struct ContentPackLoader: ContentPackProviding {
    enum LoaderError: Error, CustomStringConvertible {
        case missingResource(String)

        var description: String {
            switch self {
            case .missingResource(let name): return "Missing bundled resource: \(name)"
            }
        }
    }

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func load() throws -> ContentPack {
        let prompts: PromptPack = try decode("prompts")
        let expectations: ExpectationPack = try decode("expectations")
        return ContentPack(prompts: prompts, expectations: expectations)
    }

    private func decode<T: Decodable>(_ resource: String) throws -> T {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw LoaderError.missingResource("\(resource).json")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
