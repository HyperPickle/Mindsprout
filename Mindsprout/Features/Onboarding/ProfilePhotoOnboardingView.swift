import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct ProfilePhotoOnboardingView: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false

    var onComplete: () -> Void

    private var user: User? { users.first }

    var body: some View {
        ZStack {
            BackgroundSky()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Add a Profile Photo")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Show off your travel self.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                avatarPreview
                    .padding(.vertical, 20)
                
                VStack(spacing: 16) {
                    Button {
                        Task { await requestCameraAndShow() }
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                    }
                    .buttonStyle(.primaryWhite)
                    .frame(width: 280)
                    
                    PhotosPicker(
                        selection: $photoPickerItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 50)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button("Continue") {
                        onComplete()
                    }
                    .buttonStyle(.primaryWhite)
                    .frame(width: 280)
                    .opacity(user?.profilePhotoPath == nil ? 0.6 : 1.0)
                    
                    Button("Skip for now") {
                        onComplete()
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .sheet(isPresented: $showCamera) {
            OnboardingCameraPickerView { image in
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
        ZStack {
            if let path = user?.profilePhotoPath {
                AsyncImage(url: env.mediaStore.url(for: path)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.white.opacity(0.6))
                }
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            } else {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.6))
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 4))
            }
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
}

private struct OnboardingCameraPickerView: UIViewControllerRepresentable {
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

#Preview {
    ProfilePhotoOnboardingView(onComplete: {})
        .environment(\.appEnvironment, .preview)
}
