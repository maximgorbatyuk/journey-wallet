import SwiftUI
import Observation

enum DocumentFilter: String, CaseIterable {
    case all
    case pdf
    case images

    var displayName: String {
        switch self {
        case .all: return L("document.filter.all")
        case .pdf: return L("document.filter.pdf")
        case .images: return L("document.filter.images")
        }
    }
}

@MainActor
@Observable
class DocumentListViewModel {

    var documents: [Document] = []
    var filteredDocuments: [Document] = []
    var selectedFilter: DocumentFilter = .all {
        didSet { applyFilter() }
    }
    var isLoading: Bool = false
    var errorMessage: String?

    private let journeyId: UUID
    private let documentsRepository: DocumentsRepository?
    private let documentService = DocumentService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self.documentsRepository = DatabaseManager.shared.documentsRepository
    }

    // MARK: - Data Loading

    func loadDocuments() {
        isLoading = true
        documents = documentsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        applyFilter()
        isLoading = false
    }

    func refreshDocuments() {
        loadDocuments()
    }

    // MARK: - Filtering

    private func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredDocuments = documents
        case .pdf:
            filteredDocuments = documents.filter { $0.isPDF }
        case .images:
            filteredDocuments = documents.filter { $0.isImage }
        }
    }

    // MARK: - CRUD Operations

    func addDocument(from url: URL, name: String? = nil) -> Bool {
        guard let result = documentService.saveDocument(from: url, journeyId: journeyId) else {
            errorMessage = L("document.error.save_failed")
            return false
        }

        let documentType = documentService.getDocumentType(from: url)
        let documentName = name ?? (url.deletingPathExtension().lastPathComponent)

        let document = Document(
            journeyId: journeyId,
            name: documentName,
            fileType: documentType,
            fileName: result.fileName,
            fileSize: result.fileSize
        )

        if documentsRepository?.insert(document) == true {
            loadDocuments()
            return true
        } else {
            // Clean up file if database insert fails
            _ = documentService.deleteDocument(fileName: result.fileName, journeyId: journeyId)
            errorMessage = L("document.error.save_failed")
            return false
        }
    }

    func deleteDocument(_ document: Document) -> Bool {
        // Delete from file system
        _ = documentService.deleteDocument(fileName: document.fileName, journeyId: journeyId)

        // Delete from database
        if documentsRepository?.delete(id: document.id) == true {
            loadDocuments()
            return true
        }
        return false
    }

    func updateDocumentName(_ document: Document, newName: String) -> Bool {
        var updatedDocument = document
        updatedDocument.name = newName

        if documentsRepository?.update(updatedDocument) == true {
            loadDocuments()
            return true
        }
        return false
    }

    // MARK: - File Access

    func getDocumentURL(_ document: Document) -> URL {
        return documentService.getDocumentURL(fileName: document.fileName, journeyId: journeyId)
    }

    func documentExists(_ document: Document) -> Bool {
        return documentService.documentExists(fileName: document.fileName, journeyId: journeyId)
    }

    // MARK: - Statistics

    var totalCount: Int {
        documents.count
    }

    var pdfCount: Int {
        documents.filter { $0.isPDF }.count
    }

    var imageCount: Int {
        documents.filter { $0.isImage }.count
    }

    var totalFileSize: Int64 {
        documents.reduce(0) { $0 + $1.fileSize }
    }

    var formattedTotalSize: String {
        documentService.formattedFileSize(totalFileSize)
    }
}
