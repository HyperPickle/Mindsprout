import Foundation
import SwiftData

@Model
final class Sprout {
    var id: UUID = UUID()
    var name: String = ""
    var xp: Int = 0
    var level: Int = 1
    var currentStageIndex: Int = 0
    var currency: Int = 0
    var state: SproutState = SproutState.idle
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        xp: Int = 0,
        level: Int = 1,
        currentStageIndex: Int = 0,
        currency: Int = 0,
        state: SproutState = .idle,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.xp = xp
        self.level = level
        self.currentStageIndex = currentStageIndex
        self.currency = currency
        self.state = state
        self.createdAt = createdAt
    }
}

extension Sprout {
    /// The single global Sprout, creating it if absent. Optionally seeds the
    /// name on first creation (used by onboarding). All call sites must use
    /// this instead of inserting `Sprout()` directly.
    @discardableResult
    static func fetchOrCreate(name: String? = nil, in context: ModelContext) -> Sprout {
        var descriptor = FetchDescriptor<Sprout>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            if let name, !name.isEmpty, existing.name.isEmpty { existing.name = name }
            return existing
        }
        let sprout = Sprout(name: name?.trimmingCharacters(in: .whitespaces) ?? "")
        context.insert(sprout)
        return sprout
    }
}
