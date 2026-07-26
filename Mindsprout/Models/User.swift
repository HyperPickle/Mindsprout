import Foundation
import SwiftData

@Model
final class User {
    var appleUserID: String = ""
    var displayName: String = ""
    /// Legacy schema field. Mindsprout no longer requests or uses Apple email.
    /// Keeping it avoids a destructive change to the versioned V1 schema.
    var email: String = ""
    var createdAt: Date = Date()
    var profilePhotoPath: String? = nil

    init(
        appleUserID: String = "",
        displayName: String = "",
        email: String = "",
        createdAt: Date = Date(),
        profilePhotoPath: String? = nil
    ) {
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.email = email
        self.createdAt = createdAt
        self.profilePhotoPath = profilePhotoPath
    }

    @discardableResult
    static func upsert(
        appleUserID: String,
        displayName: String?,
        in context: ModelContext
    ) -> User {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == appleUserID }
        )
        if let existing = try? context.fetch(descriptor).first {
            if let displayName, !displayName.isEmpty { existing.displayName = displayName }
            existing.email = ""
            try? context.save()
            return existing
        }
        let user = User(
            appleUserID: appleUserID,
            displayName: displayName ?? ""
        )
        context.insert(user)
        try? context.save()
        return user
    }

    static func current(in users: [User], userID: String?) -> User? {
        guard let userID, !userID.isEmpty else {
            return users.first(where: { $0.appleUserID.isEmpty }) ?? users.first
        }
        return users.first(where: { $0.appleUserID == userID })
    }

    @discardableResult
    static func fetchOrCreateLocal(in context: ModelContext) -> User {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == "" }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.email = ""
            try? context.save()
            return existing
        }

        let user = User()
        context.insert(user)
        try? context.save()
        return user
    }

    static func removeLegacyEmails(in context: ModelContext) {
        guard let users = try? context.fetch(FetchDescriptor<User>()) else { return }
        let usersWithEmail = users.filter { !$0.email.isEmpty }
        guard !usersWithEmail.isEmpty else { return }
        usersWithEmail.forEach { $0.email = "" }
        try? context.save()
    }

    var resolvedDisplayName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Traveler" : trimmed
    }
}
