import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import UIKit

struct ProfilePhotoEditorContent: View {
    enum Style: Equatable {
        case onboarding
        case modal

        var avatarSize: CGFloat {
            switch self {
            case .onboarding: return 180
            case .modal: return 100
            }
        }

        var avatarPadding: CGFloat {
            switch self {
            case .onboarding: return 20
            case .modal: return 0
            }
        }

        var actionWidth: CGFloat? {
            switch self {
            case .onboarding: return 320
            case .modal: return nil
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.appEnvironment) private var env
    @Query private var users: [User]

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false

    let style: Style
    var userID: String? = nil
    var showsRemoveButton = false

    private var resolvedUserID: String? {
        userID ?? env.auth.state.userID
    }

    private var user: User? { User.current(in: users, userID: resolvedUserID) }

    var body: some View {
        VStack(spacing: 24) {
            avatarPreview
                .padding(.vertical, style.avatarPadding)

            actionList
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
            .frame(width: style.avatarSize, height: style.avatarSize)
            .clipShape(Circle())
            .overlay {
                if style == .onboarding {
                    Circle().stroke(Color.white, lineWidth: 4)
                }
            }
            .shadow(
                color: .black.opacity(style == .onboarding ? 0.2 : 0.12),
                radius: style == .onboarding ? 20 : 8,
                y: style == .onboarding ? 10 : 4
            )
        } else {
            Circle()
                .fill(style == .onboarding ? .white.opacity(0.2) : .white)
                .frame(width: style.avatarSize, height: style.avatarSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: style.avatarSize * 0.4))
                        .foregroundColor(.gray.opacity(style == .onboarding ? 0.6 : 0.4))
                }
                .overlay {
                    if style == .onboarding {
                        Circle().stroke(Color.white.opacity(0.4), lineWidth: 4)
                    }
                }
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
    }

    @ViewBuilder
    private var actionList: some View {
        switch style {
        case .onboarding:
            VStack(spacing: 16) {
                Button {
                    Task { await requestCameraAndShow() }
                } label: {
                    actionRow(title: "Take Photo", systemImage: "camera.fill", foregroundColor: AppColor.label)
                }
                .buttonStyle(.primaryWhiteSentenceCase)
                .frame(width: style.actionWidth)

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    actionRow(
                        title: "Choose from Library",
                        systemImage: "photo.on.rectangle",
                        foregroundColor: AppColor.label
                    )
                }
                .buttonStyle(.primaryWhiteSentenceCase)
                .frame(width: style.actionWidth)
            }

        case .modal:
            VStack(spacing: 0) {
                Button {
                    Task { await requestCameraAndShow() }
                } label: {
                    actionRow(title: "Take Photo", systemImage: "camera")
                        .padding(.vertical, 12)
                }

                Divider()

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    actionRow(title: "Choose from Library", systemImage: "photo.on.rectangle")
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if showsRemoveButton, user?.profilePhotoPath != nil {
                    Divider()

                    Button(role: .destructive) {
                        removePhoto()
                    } label: {
                        actionRow(title: "Remove Photo", systemImage: "trash", foregroundColor: .red)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private func actionRow(
        title: String,
        systemImage: String,
        foregroundColor: Color = .primary
    ) -> some View {
        ZStack {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 24)
                Spacer()
            }

            Text(title)
                .font(AppFont.button)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func requestCameraAndShow() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                showCamera = true
            } else {
                showCameraPermissionAlert = true
            }
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

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
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
