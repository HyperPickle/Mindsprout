import SwiftUI
import UIKit
import PhotosUI
import AVFoundation
import SwiftData

enum AppThemePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { self.rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // nil = primary AppIcon, which adapts to the system appearance on its own.
    var alternateIconName: String? {
        switch self {
        case .system: return nil
        case .light: return "AppIconLight"
        case .dark: return "AppIconDark"
        }
    }
}

@MainActor
enum AppIconManager {
    static func apply(_ preference: AppThemePreference) {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons else { return }
        let target = preference.alternateIconName
        guard app.alternateIconName != target else { return }
        app.setAlternateIconName(target)
    }
}

private struct ModalScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            content
        }
        .padding(20)
        .selfSizingSheet()
    }
}

private struct SelfSizingSheet: ViewModifier {
    @State private var height: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { height = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, newValue in height = newValue }
                }
            }
            .presentationDetents(height > 0 ? [.height(height)] : [.medium])
    }
}

private extension View {
    func selfSizingSheet() -> some View { modifier(SelfSizingSheet()) }
}

struct ThemeSettingsModal: View {
    @AppStorage("appThemePreference") private var themePreference: AppThemePreference = .system

    var body: some View {
        ModalScaffold(title: "Appearance") {
            VStack(spacing: 0) {
                ForEach(AppThemePreference.allCases) { theme in
                    Button {
                        themePreference = theme
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if themePreference == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    if theme != AppThemePreference.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }
}

struct ShopComingSoonModal: View {
    var body: some View {
        ModalScaffold(title: "Shop") {
            VStack(spacing: 12) {
                Image(systemName: "bag")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("Shop Coming Soon")
                    .font(.headline)
                Text("We're working on bringing you the shop in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct HelpSupportModal: View {
    var body: some View {
        ModalScaffold(title: "Help & Support") {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Us")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Button("Email Support") { }
                    Button("Report a Bug") { }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("FAQ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text("How do I earn XP?")
                    Text("Can I change my avatar?")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AboutSettingsModal: View {
    var body: some View {
        ModalScaffold(title: "About") {
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Mindsprout")
                    .font(.largeTitle.bold())

                Text("Grow your mind, one reflection at a time.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 6) {
                    Text("Developed by")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    VStack(spacing: 4) {
                        Text("Rishi Singhal")
                        Text("Changrila Souksamlane")
                        Text("Hiu Ying Lee (Ruby)")
                        Text("Nam Ng. (Louis)")
                        Text("Arshiya Banu Varada")
                    }
                    .font(.subheadline)
                }

                Text("© 2026 Mindsprout")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct ProfilePhotoModal: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appEnvironment) private var env
    @Query private var users: [User]

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false

    private var user: User? { users.first }

    var body: some View {
        ModalScaffold(title: "Profile Photo") {
            VStack(spacing: 24) {
                avatarPreview

                VStack(spacing: 0) {
                    Button {
                        Task { await requestCameraAndShow() }
                    } label: {
                        HStack {
                            Text("Take Photo")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "camera")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }

                    Divider()

                    PhotosPicker(
                        selection: $photoPickerItem,
                        matching: .images
                    ) {
                        HStack {
                            Text("Choose from Library")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "photo.on.rectangle")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if user?.profilePhotoPath != nil {
                        Divider()

                        Button(role: .destructive) {
                            removePhoto()
                        } label: {
                            HStack {
                                Text("Remove Photo")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ProfileCameraPickerView { image in
                Task { await saveImage(image) }
            }
        }
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow camera access in Settings to take photos.")
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task { await handlePickedItem(item) }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let path = user?.profilePhotoPath {
            AsyncImage(url: env.mediaStore.url(for: path)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(.white.opacity(0.6))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        } else {
            Circle()
                .fill(.white)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                )
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
    }

    private func requestCameraAndShow() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { showCamera = true } else { showCameraPermissionAlert = true }
        default:
            showCameraPermissionAlert = true
        }
    }

    private func handlePickedItem(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await savePhotoData(data)
        photoPickerItem = nil
    }

    private func saveImage(_ image: UIImage?) async {
        guard let image, let data = image.jpegData(compressionQuality: 0.85) else { return }
        await savePhotoData(data)
    }

    @MainActor
    private func savePhotoData(_ data: Data) async {
        guard let user else { return }
        if let oldPath = user.profilePhotoPath {
            try? env.mediaStore.delete(relativePath: oldPath)
        }
        guard let path = try? env.mediaStore.write(data, kind: .photo, fileExtension: "jpg") else { return }
        user.profilePhotoPath = path
        try? modelContext.save()
    }

    private func removePhoto() {
        guard let user, let path = user.profilePhotoPath else { return }
        try? env.mediaStore.delete(relativePath: path)
        user.profilePhotoPath = nil
        try? modelContext.save()
    }
}

private struct ProfileCameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            picker.dismiss(animated: true)
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCapture(nil)
        }
    }
}
