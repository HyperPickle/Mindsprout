import SwiftUI
import SwiftData
import UIKit

// Resolves a photo MediaAsset id to its on-disk file and renders it.
struct MediaImage: View {
    let assetID: UUID?
    var contentMode: ContentMode = .fill

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle().fill(AppColor.hairline.opacity(0.5))
            }
        }
        .task(id: assetID) { await load() }
    }

    private func load() async {
        guard let assetID else { image = nil; return }
        let store = env.mediaStore
        guard let path = Self.relativePath(for: assetID, in: context) else { image = nil; return }
        let url = store.url(for: path)
        let loaded = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: url.path)
        }.value
        image = loaded
    }

    static func relativePath(for id: UUID, in context: ModelContext) -> String? {
        var descriptor = FetchDescriptor<MediaAsset>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first?.relativePath
    }
}
