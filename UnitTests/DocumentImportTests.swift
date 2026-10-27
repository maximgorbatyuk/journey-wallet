import Foundation
@testable import JourneyWallet_Dev
import SQLite
import Testing

@MainActor
struct DocumentImportTests {
    @Test func importDocument_returnsThePersistedDocument() throws {
        let connection = try Connection(.inMemory)
        Migration_20260118_JourneyTables(db: connection).execute()
        Migration_20260119_DocumentFilePath(db: connection).execute()
        let repository = DocumentsRepository(db: connection, tableName: "documents")
        let journeyId = UUID()
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        try Data("Test document".utf8).write(to: source)
        defer {
            try? FileManager.default.removeItem(at: source)
            _ = DocumentService.shared.deleteAllDocuments(journeyId: journeyId)
        }
        let viewModel = DocumentListViewModel(journeyId: journeyId, documentsRepository: repository)
        let document = try #require(viewModel.importDocument(from: source, name: "Booking"))
        let stored = try #require(repository.fetchById(id: document.id))
        #expect(stored.fileName == document.fileName)
        #expect(stored.name == document.name)
        #expect(abs(stored.createdAt.timeIntervalSince(document.createdAt)) < 0.001)
        #expect(document.journeyId == journeyId)
        #expect(document.name == "Booking")
        #expect(viewModel.documentExists(document))
    }

    @Test func importDocument_whenDatabaseFails_removesCopiedFile() throws {
        let connection = try Connection(.inMemory)
        let journeyId = UUID()
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        try Data("Test document".utf8).write(to: source)
        defer {
            try? FileManager.default.removeItem(at: source)
            _ = DocumentService.shared.deleteAllDocuments(journeyId: journeyId)
        }
        let viewModel = DocumentListViewModel(
            journeyId: journeyId, documentsRepository: DocumentsRepository(db: connection, tableName: "missing")
        )
        #expect(viewModel.importDocument(from: source) == nil)
        let directory = DocumentService.shared.getJourneyDocumentsDirectory(journeyId: journeyId)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
        #expect(viewModel.errorMessage != nil)
    }
}
