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
    private let journeysRepository: JourneysRepository?
    private let notesRepository: NotesRepository?
    private let documentService = DocumentService.shared

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.documentsRepository = databaseManager.documentsRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.notesRepository = databaseManager.notesRepository
    }

    init(journeyId: UUID, documentsRepository: DocumentsRepository?, journeysRepository: JourneysRepository? = nil) {
        self.journeyId = journeyId
        self.documentsRepository = documentsRepository
        self.journeysRepository = journeysRepository
        self.notesRepository = nil
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

    func addDocument(from url: URL, name: String? = nil, filePath: String? = nil) -> Bool {
        importDocument(from: url, name: name, filePath: filePath) != nil
    }

    func importDocument(from url: URL, name: String? = nil, filePath: String? = nil) -> Document? {
        errorMessage = nil
        guard let result = documentService.saveDocument(from: url, journeyId: journeyId) else {
            errorMessage = L("document.error.save_failed")
            return nil
        }

        let documentType = documentService.getDocumentType(from: url)
        let documentName: String? = (name?.isEmpty == false) ? name : nil

        let document = Document(
            journeyId: journeyId,
            name: documentName,
            fileType: documentType,
            fileName: result.fileName,
            filePath: filePath,
            fileSize: result.fileSize
        )

        if documentsRepository?.insert(document) == true {
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadDocuments()
            return document
        } else {
            // Clean up file if database insert fails
            _ = documentService.deleteDocument(fileName: result.fileName, journeyId: journeyId)
            errorMessage = L("document.error.save_failed")
            return nil
        }
    }

    func deleteDocument(_ document: Document) -> Bool {
        // Delete from file system
        _ = documentService.deleteDocument(fileName: document.fileName, journeyId: journeyId)

        // Delete from database
        if documentsRepository?.delete(id: document.id) == true {
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadDocuments()
            return true
        }
        return false
    }

    func updateDocumentName(_ document: Document, newName: String?) -> Bool {
        var updatedDocument = document
        updatedDocument.name = newName

        if documentsRepository?.update(updatedDocument) == true {
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadDocuments()
            return true
        }
        return false
    }

    func moveToJourney(document: Document, newJourneyId: UUID) -> Bool {
        if documentsRepository?.updateJourneyId(id: document.id, newJourneyId: newJourneyId) == true {
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            journeysRepository?.touchUpdatedAt(journeyId: newJourneyId)
            loadDocuments()
            return true
        }
        return false
    }

    func hasNoteAttachments(_ document: Document) -> Bool {
        notesRepository?.fetchAllDocumentAttachments().contains { $0.documentId == document.id } ?? false
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
