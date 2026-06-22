import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct PhotoCommitStep: View {
    @Bindable var vm: ReflectionViewModel

    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showCameraPermissionAlert = false
    @State private var lightboxID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    sproutHeader
                    photoCard
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            ctaStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(BackgroundSky())
        .sheet(item: $lightboxID) { id in
            LightboxView(assetID: id)
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
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
        .onChange(of: photoPickerItems) { _, items in
            Task { await handlePickedItems(items) }
        }
    }

    private var sproutHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button { vm.step = 2 } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(AppFont.callout)
                .foregroundStyle(AppColor.onBackground)
            }
            .buttonStyle(.plain)

            HStack(alignment: .center, spacing: Spacing.sm) {
                SproutIdleView()
                    .frame(width: 95, height: 95)
                Text("A picture worth a thousand words they say ;)")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.onBackground)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var photoCard: some View {
        if vm.photoAssetIDs.isEmpty {
            emptyPhotoCard
        } else {
            filledPhotoCard
        }
    }

    private var emptyPhotoCard: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "camera")
                .font(.system(size: 52))
                .foregroundStyle(AppColor.hairline)

            VStack(spacing: Spacing.sm) {
                cameraButton
                libraryButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .glassEffect(.regular.tint(.white), in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }

    private var filledPhotoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(vm.photoAssetIDs, id: \.self) { id in
                        ZStack(alignment: .topTrailing) {
                            MediaImage(assetID: id, contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                                .onTapGesture { lightboxID = id }
                            Button {
                                vm.photoAssetIDs.removeAll { $0 == id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                                    .contentShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                    addMoreButton
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.md)
        }
        .glassEffect(.regular.tint(.white), in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }

    private var addMoreButton: some View {
        Menu {
            Button {
                Task { await requestCameraAndShow() }
            } label: {
                Label("Take a photo", systemImage: "camera")
            }
            PhotosPickerWrapper(items: $photoPickerItems) {
                Label("Choose from album", systemImage: "photo.on.rectangle")
            }
        } label: {
            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                .fill(Color.white.opacity(0.35))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(AppColor.inkSecondary)
                }
                .contentShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var cameraButton: some View {
        Button {
            Task { await requestCameraAndShow() }
        } label: {
            Label("Take a photo", systemImage: "camera")
                .font(AppFont.body)
                .foregroundStyle(AppColor.ink)
                .frame(maxWidth: 220)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(.white).shadow(color: AppColor.ink.opacity(0.1), radius: 4, y: 2))
                .overlay(Capsule().stroke(AppColor.hairline, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var libraryButton: some View {
        PhotosPickerWrapper(items: $photoPickerItems) {
            Label("Choose from album", systemImage: "photo.on.rectangle")
                .font(AppFont.body)
                .foregroundStyle(AppColor.ink)
                .frame(maxWidth: 220)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(.white).shadow(color: AppColor.ink.opacity(0.1), radius: 4, y: 2))
                .overlay(Capsule().stroke(AppColor.hairline, lineWidth: 1))
                .contentShape(Capsule())
        }
    }

    private var ctaStack: some View {
        VStack(spacing: Spacing.sm) {
            Button("Feed Sprout") { vm.feedSprout() }
                .buttonStyle(.primaryWhite)
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.bottom, Spacing.md)
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

    private func handlePickedItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let path = try? vm.mediaStore.write(data, kind: .photo, fileExtension: "jpg") {
                let asset = MediaAsset(kind: .photo, relativePath: path)
                vm.context.insert(asset)
                vm.photoAssetIDs.append(asset.id)
            }
        }
        photoPickerItems = []
    }

    private func saveImage(_ image: UIImage?) async {
        guard let image, let data = image.jpegData(compressionQuality: 0.85) else { return }
        if let path = try? vm.mediaStore.write(data, kind: .photo, fileExtension: "jpg") {
            let asset = MediaAsset(kind: .photo, relativePath: path)
            vm.context.insert(asset)
            vm.photoAssetIDs.append(asset.id)
        }
    }
}

// MARK: - PhotosPicker wrapper

private struct PhotosPickerWrapper<Label: View>: View {
    @Binding var items: [PhotosPickerItem]
    let label: () -> Label

    var body: some View {
        PhotosPicker(
            selection: $items,
            maxSelectionCount: 5,
            matching: .images
        ) {
            label()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Camera UIImagePickerController wrapper

private struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCapture(nil)
        }
    }
}

// MARK: - Lightbox

private struct LightboxView: View {
    let assetID: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            MediaImage(assetID: assetID, contentMode: .fit)
                .ignoresSafeArea()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .padding(Spacing.md)
                    .contentShape(Circle())
            }
        }
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

#Preview {
    let vm = ReflectionViewModel(
        tripID: UUID(),
        context: ModelContext(PersistenceController.makeInMemoryContainer()),
        contentPack: ContentPack(
            prompts: PromptPack(highlightPrompts: [:], inspirationPrompts: []),
            expectations: ExpectationPack(presets: [:])
        ),
        mediaStore: MediaStore(root: FileManager.default.temporaryDirectory),
        gameConfig: .default,
        ai: TemplateAIGenerationService(),
        tripType: .solo,
        onDismiss: {}
    )
    PhotoCommitStep(vm: vm)
}
