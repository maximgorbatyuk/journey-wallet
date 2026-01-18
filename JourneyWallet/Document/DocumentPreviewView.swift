import SwiftUI
import PDFKit
import QuickLook

struct DocumentPreviewView: View {

    let document: Document
    let journeyId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showRenameSheet = false
    @State private var newName: String = ""
    @ObservedObject private var analytics = AnalyticsService.shared

    private var documentURL: URL {
        DocumentService.shared.getDocumentURL(fileName: document.fileName, journeyId: journeyId)
    }

    var body: some View {
        NavigationView {
            Group {
                if document.isPDF {
                    PDFViewerView(url: documentURL)
                } else if document.isImage {
                    ImageViewerView(url: documentURL)
                } else {
                    unsupportedView
                }
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Close")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label(L("document.action.share"), systemImage: "square.and.arrow.up")
                        }

                        Button {
                            newName = document.name
                            showRenameSheet = true
                        } label: {
                            Label(L("document.action.rename"), systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                analytics.trackScreen("document_preview_screen")
                analytics.trackEvent("document_viewed", properties: ["type": document.fileType.rawValue])
            }
            .sheet(isPresented: $showShareSheet) {
                DocumentShareSheet(activityItems: [documentURL])
            }
            .alert(L("document.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
                Button(L("Cancel"), role: .cancel) {}
                Button(L("Delete"), role: .destructive) {
                    deleteDocument()
                }
            } message: {
                Text(L("document.delete_confirm.message"))
            }
            .alert(L("document.rename.title"), isPresented: $showRenameSheet) {
                TextField(L("document.rename.placeholder"), text: $newName)
                Button(L("Cancel"), role: .cancel) {}
                Button(L("Save")) {
                    renameDocument()
                }
            } message: {
                Text(L("document.rename.message"))
            }
        }
    }

    // MARK: - Unsupported View

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(L("document.preview.unsupported"))
                .font(.headline)
                .foregroundColor(.gray)

            Button {
                showShareSheet = true
            } label: {
                Label(L("document.action.open_in"), systemImage: "arrow.up.forward.app")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Actions

    private func deleteDocument() {
        let viewModel = DocumentListViewModel(journeyId: journeyId)
        _ = viewModel.deleteDocument(document)
        dismiss()
    }

    private func renameDocument() {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let viewModel = DocumentListViewModel(journeyId: journeyId)
        _ = viewModel.updateDocumentName(document, newName: newName.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - PDF Viewer

struct PDFViewerView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Image Viewer

struct ImageViewerView: View {

    let url: URL

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1), 5)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale > 1 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(L("document.preview.image_error"))
                        .foregroundColor(.secondary)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(Color.black)
    }

    private func loadImage() -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Share Sheet

struct DocumentShareSheet: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DocumentPreviewView(
        document: Document(
            journeyId: UUID(),
            name: "Test Document",
            fileType: .pdf,
            fileName: "test.pdf",
            fileSize: 1024
        ),
        journeyId: UUID()
    )
}
