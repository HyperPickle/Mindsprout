import Foundation

enum AppleCredentialRevocationError: Error, Equatable {
    case missingEndpoint
    case invalidResponse
    case serverRejected(statusCode: Int)
}

protocol AppleCredentialRevoking: Sendable {
    func revoke(authorizationCode: String) async throws
}

struct AppleCredentialRevocationService: AppleCredentialRevoking {
    private let endpoint: URL?
    private let session: URLSession

    init(
        endpoint: URL? = AppleCredentialRevocationService.defaultEndpoint,
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.session = session
    }

    func revoke(authorizationCode: String) async throws {
        guard let endpoint else {
            throw AppleCredentialRevocationError.missingEndpoint
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RevocationRequest(authorizationCode: authorizationCode))

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppleCredentialRevocationError.invalidResponse
        }
        guard httpResponse.statusCode == 204 else {
            throw AppleCredentialRevocationError.serverRejected(statusCode: httpResponse.statusCode)
        }
    }

    private static var defaultEndpoint: URL? {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "MSAppleRevokeEndpoint") as? String,
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(string: configured)
        }
        return URL(string: "https://mindsprout-proxy.vercel.app/api/apple/revoke")
    }

    private struct RevocationRequest: Encodable {
        var authorizationCode: String
    }
}

struct NoOpAppleCredentialRevocationService: AppleCredentialRevoking {
    func revoke(authorizationCode: String) async throws {}
}
