//
//  AnalyticsService.swift
//  Mindsprout
//
//  DOCUMENTED SEAM — unimplemented for MVP (Plan §2: "No analytics (future)").
//  The protocol exists so feature code can record events from day one; the
//  shipped implementation is a no-op. A real analytics backend conforms to this
//  protocol and is swapped in at the composition root — no feature changes.
//

import Foundation

/// A lightweight, fire-and-forget analytics event.
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

/// Default MVP implementation: discards everything. Intentionally does nothing.
struct NoOpAnalyticsService: AnalyticsService {
    func log(_ event: AnalyticsEvent) {
        // No analytics for MVP. Replace at the composition root when added.
    }
}
