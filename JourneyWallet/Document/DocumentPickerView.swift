import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct DocumentPickerView: View {

    let journeyId: UUID
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDocumentPicker = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @ObservedObject private var analytics = AnalyticsService.shared

    var body: some View {
        NavigationView {
            List {
                Section {
                    // Import from Files
                    Button {
                        showDocumentPicker = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("document.import.files"))
                                    .foregroundColor(.primary)
                                Text(L("document.import.files.description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    // Import from Photos
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("document.import.photos"))
                                    .foregroundColor(.primary)
                                Text(L("document.import.photos.description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "photo.fill")
                                .foregroundColor(.green)
                        }
                    }

                    // Take Photo
                    Button {
                        showCamera = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("document.import.camera"))
                                    .foregroundColor(.primary)
                                Text(L("document.import.camera.description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text(L("document.import.section.source"))
                } footer: {
                    Text(L("document.import.supported_formats"))
                }
            }
            .navigationTitle(L("document.import.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(L("document.import.processing"))
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    }
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.pdf, .jpeg, .png, .heic],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedPhotoItems) { _, newItems in
                handlePhotoSelection(newItems)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    handleCapturedImage(image)
                }
            }
            .alert(L("Error"), isPresented: $showError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? L("document.error.unknown"))
            }
            .onAppear {
                analytics.trackScreen("document_picker_screen")
            }
        }
    }

    // MARK: - File Import Handling

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processFiles(urls)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func processFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        isProcessing = true

        Task {
            var successCount = 0

            for url in urls {
                if DocumentService.shared.isSupportedFileType(url) {
                    let viewModel = DocumentListViewModel(journeyId: journeyId)
                    if viewModel.addDocument(from: url) {
                        successCount += 1
                    }
                }
            }

            await MainActor.run {
                isProcessing = false

                if successCount > 0 {
                    analytics.trackEvent("documents_imported", properties: ["count": successCount])
                    onComplete(true)
                    dismiss()
                } else {
                    errorMessage = L("document.error.import_failed")
                    showError = true
                }
            }
        }
    }

    // MARK: - Photo Selection Handling

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        isProcessing = true
        selectedPhotoItems = []

        Task {
            var successCount = 0

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // Determine file type from the photo
                    let fileName = "photo_\(UUID().uuidString).jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                    do {
                        try data.write(to: tempURL)
                        let viewModel = DocumentListViewModel(journeyId: journeyId)
                        if viewModel.addDocument(from: tempURL) {
                            successCount += 1
                        }
                        try? FileManager.default.removeItem(at: tempURL)
                    } catch {
                        print("Failed to process photo: \(error)")
                    }
                }
            }

            await MainActor.run {
                isProcessing = false

                if successCount > 0 {
                    analytics.trackEvent("photos_imported", properties: ["count": successCount])
                    onComplete(true)
                    dismiss()
                } else {
                    errorMessage = L("document.error.import_failed")
                    showError = true
                }
            }
        }
    }

    // MARK: - Camera Capture Handling

    private func handleCapturedImage(_ image: UIImage?) {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        isProcessing = true

        Task {
            let fileName = "capture_\(UUID().uuidString).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try data.write(to: tempURL)
                let viewModel = DocumentListViewModel(journeyId: journeyId)
                let success = viewModel.addDocument(from: tempURL, name: L("document.camera.default_name"))
                try? FileManager.default.removeItem(at: tempURL)

                await MainActor.run {
                    isProcessing = false

                    if success {
                        analytics.trackEvent("photo_captured")
                        onComplete(true)
                        dismiss()
                    } else {
                        errorMessage = L("document.error.save_failed")
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {

    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

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

#Preview {
    DocumentPickerView(journeyId: UUID()) { _ in }
}
