import Foundation
import SwiftData

@Model
final class User {
    var appleUserID: String = ""
    var displayName: String = ""
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
        email: String?,
        in context: ModelContext
    ) -> User {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == appleUserID }
        )
        if let existing = try? context.fetch(descriptor).first {
            if let displayName, !displayName.isEmpty { existing.displayName = displayName }
            if let email, !email.isEmpty { existing.email = email }
            try? context.save()
            return existing
        }
        let user = User(
            appleUserID: appleUserID,
            displayName: displayName ?? "",
            email: email ?? ""
        )
        context.insert(user)
        try? context.save()
        return user
    }
}
