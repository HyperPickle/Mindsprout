import Foundation

struct AnalyticsEvent: Sendable {
    var name: String
    var parameters: [String: String]

    init(_ name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

protocol AnalyticsService: Sendable {
    func log(_ event: AnalyticsEvent)
}

struct NoOpAnalyticsService: AnalyticsService {
    func log(_ event: AnalyticsEvent) {}
}
