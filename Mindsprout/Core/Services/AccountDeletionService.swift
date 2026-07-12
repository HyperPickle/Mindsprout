import Foundation
import SwiftData

@MainActor
struct AccountDeletionService {
    static let defaultKeysToRemove = [
        AppleAuthService.isLoggedInKey,
        "hasCompletedOnboarding",
        "sproutName",
        "sproutLevel",
        "sproutGlassesChoice"
    ]

    var mediaStore: any MediaStoring
    var defaults: UserDefaults
    var auth: any AuthService

    init(
        mediaStore: any MediaStoring,
        defaults: UserDefaults = .standard,
        auth: any AuthService
    ) {
        self.mediaStore = mediaStore
        self.defaults = defaults
        self.auth = auth
    }

    func deleteAccount(in context: ModelContext) throws {
        let users = try context.fetch(FetchDescriptor<User>())
        let mediaAssets = try context.fetch(FetchDescriptor<MediaAsset>())

        let mediaPaths = Set(mediaAssets.map(\.relativePath) + users.compactMap(\.profilePhotoPath))
        for path in mediaPaths where !path.isEmpty {
            try mediaStore.delete(relativePath: path)
        }

        try deleteRows(of: Reflection.self, in: context)
        try deleteRows(of: Trip.self, in: context)
        try deleteRows(of: MediaAsset.self, in: context)
        try deleteRows(of: Sprout.self, in: context)
        try deleteRows(of: User.self, in: context)
        try context.save()

        clearDefaults()
        auth.deleteLocalAccountIdentity()
    }

    private func deleteRows<T: PersistentModel>(of modelType: T.Type, in context: ModelContext) throws {
        for model in try context.fetch(FetchDescriptor<T>()) {
            context.delete(model)
        }
    }

    private func clearDefaults() {
        for key in Self.defaultKeysToRemove {
            defaults.removeObject(forKey: key)
        }

        defaults.dictionaryRepresentation().keys
            .filter { key in
                key.hasPrefix("reflected_")
                    || key.hasPrefix(AppleAuthService.cachedProfileKeyPrefix)
            }
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
