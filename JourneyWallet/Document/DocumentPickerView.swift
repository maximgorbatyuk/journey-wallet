import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

/// Represents a file pending name entry before saving
struct PendingDocument: Identifiable {
    let id = UUID()
    let tempURL: URL
    let originalPath: String
    let fileName: String
    let fileSize: Int64
    let nameRequired: Bool
}

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
    @State private var pendingDocuments: [PendingDocument] = []
    @State private var currentPendingIndex: Int = 0
    @State private var showNameEntry = false
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
            .sheet(isPresented: $showNameEntry) {
                if currentPendingIndex < pendingDocuments.count {
                    let pending = pendingDocuments[currentPendingIndex]
                    DocumentNameEntryView(
                        fileName: pending.fileName,
                        filePath: pending.originalPath,
                        fileSize: pending.fileSize,
                        nameRequired: pending.nameRequired,
                        onSave: { name in
                            saveCurrentPendingDocument(withName: name)
                        },
                        onCancel: {
                            cancelPendingDocuments()
                        }
                    )
                }
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
            var pending: [PendingDocument] = []

            for url in urls {
                // Start accessing the security-scoped resource
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                if DocumentService.shared.isSupportedFileType(url) {
                    // Get file info
                    let fileName = url.lastPathComponent
                    let originalPath = url.deletingLastPathComponent().path
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

                    // Copy to temp location for later processing
                    let tempFileName = "\(UUID().uuidString)_\(fileName)"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)

                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        pending.append(PendingDocument(
                            tempURL: tempURL,
                            originalPath: originalPath,
                            fileName: fileName,
                            fileSize: fileSize,
                            nameRequired: false
                        ))
                    } catch {
                        print("Failed to copy file to temp: \(error)")
                    }
                }
            }

            await MainActor.run {
                isProcessing = false

                if pending.isEmpty {
                    errorMessage = L("document.error.import_failed")
                    showError = true
                } else {
                    pendingDocuments = pending
                    currentPendingIndex = 0
                    showNameEntry = true
                }
            }
        }
    }

    // MARK: - Pending Document Handling

    private func saveCurrentPendingDocument(withName name: String?) {
        guard currentPendingIndex < pendingDocuments.count else { return }

        let pending = pendingDocuments[currentPendingIndex]
        let viewModel = DocumentListViewModel(journeyId: journeyId)

        // Save with optional name and file path
        _ = viewModel.addDocument(from: pending.tempURL, name: name, filePath: pending.originalPath)

        // Clean up temp file
        try? FileManager.default.removeItem(at: pending.tempURL)

        // Move to next pending document or finish
        currentPendingIndex += 1

        if currentPendingIndex < pendingDocuments.count {
            // Show name entry for next document
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showNameEntry = true
            }
        } else {
            // All documents processed
            analytics.trackEvent("documents_imported", properties: ["count": pendingDocuments.count])
            pendingDocuments = []
            onComplete(true)
            dismiss()
        }
    }

    private func cancelPendingDocuments() {
        // Clean up all temp files
        for pending in pendingDocuments {
            try? FileManager.default.removeItem(at: pending.tempURL)
        }
        pendingDocuments = []
        currentPendingIndex = 0
    }

    // MARK: - Photo Selection Handling

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        isProcessing = true
        selectedPhotoItems = []

        Task {
            var pending: [PendingDocument] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // Determine file type from the photo
                    let fileName = "photo_\(UUID().uuidString).jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                    do {
                        try data.write(to: tempURL)
                        let fileSize = Int64(data.count)
                        pending.append(PendingDocument(
                            tempURL: tempURL,
                            originalPath: L("document.source.photo_library"),
                            fileName: fileName,
                            fileSize: fileSize,
                            nameRequired: true
                        ))
                    } catch {
                        print("Failed to process photo: \(error)")
                    }
                }
            }

            await MainActor.run {
                isProcessing = false

                if pending.isEmpty {
                    errorMessage = L("document.error.import_failed")
                    showError = true
                } else {
                    pendingDocuments = pending
                    currentPendingIndex = 0
                    showNameEntry = true
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
                let fileSize = Int64(data.count)

                await MainActor.run {
                    isProcessing = false

                    pendingDocuments = [PendingDocument(
                        tempURL: tempURL,
                        originalPath: L("document.source.camera"),
                        fileName: fileName,
                        fileSize: fileSize,
                        nameRequired: true
                    )]
                    currentPendingIndex = 0
                    showNameEntry = true
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
