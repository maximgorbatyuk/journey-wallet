import Foundation
@testable import JourneyWallet_Dev
import SQLite
import Testing

struct NotesPersistenceTests {
    private func database() throws -> Connection {
        let connection = try Connection(.inMemory)
        Migration_20260118_JourneyTables(db: connection).execute()
        Migration_20260119_DocumentFilePath(db: connection).execute()
        try Migration20261027NoteAttachments(db: connection).execute()
        return connection
    }

    private func document(_ journeyId: UUID) -> Document {
        Document(journeyId: journeyId, name: "Confirmation", fileType: .pdf, fileName: "booking.pdf", fileSize: 128)
    }
    @Test func save_withLinksAndDocuments_preservesOrderAndCreatedAt() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let journeyId = UUID()
        let first = document(journeyId)
        let second = document(journeyId)
        #expect(documents.insert(first))
        #expect(documents.insert(second))
        var note = Note(
            journeyId: journeyId,
            title: "Check in",
            content: "Use the side entrance",
            createdAt: Date(timeIntervalSince1970: 1_790_000_000)
        )
        let createdAt = note.createdAt
        let links = [NoteLink(noteId: note.id, title: "Entrance", url: "https://maps.google.com/?q=hotel")]
        #expect(repository.save(note, links: links, documentIds: [second.id, first.id]))
        #expect(repository.fetchLinks(noteId: note.id) == links)
        #expect(repository.fetchDocuments(noteId: note.id).map(\.id) == [second.id, first.id])
        note.title = "Arrival"
        #expect(repository.save(note, links: [], documentIds: [first.id]))
        #expect(repository.fetchLinks(noteId: note.id).isEmpty)
        #expect(repository.fetchDocuments(noteId: note.id).map(\.id) == [first.id])
        #expect(repository.fetchById(id: note.id)?.createdAt == createdAt)
    }

    @Test func save_withDuplicateDocuments_deduplicatesBindings() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let doc = document(UUID())
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Trip", content: "")
        #expect(repository.save(note, links: [], documentIds: [doc.id, doc.id]))
        #expect(repository.fetchDocuments(noteId: note.id).map(\.id) == [doc.id])
    }

    @Test func save_withForeignDocument_rollsBackNoteAndAttachments() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let doc = document(UUID())
        let foreign = document(UUID())
        #expect(documents.insert(doc))
        #expect(documents.insert(foreign))
        var note = Note(journeyId: doc.journeyId, title: "Original", content: "Saved")
        let links = [NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")]
        #expect(repository.save(note, links: links, documentIds: [doc.id]))
        note.title = "Unsaved"
        #expect(!repository.save(note, links: [], documentIds: [foreign.id]))
        #expect(repository.fetchById(id: note.id)?.title == "Original")
        #expect(repository.fetchLinks(noteId: note.id) == links)
        #expect(repository.fetchDocuments(noteId: note.id).map(\.id) == [doc.id])
    }

    @Test func save_whenLinkInsertFails_rollsBackEntireChange() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        var note = Note(journeyId: UUID(), title: "Original", content: "Saved")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: []))
        note.title = "Unsaved"
        #expect(!repository.save(note, links: [link, link], documentIds: []))
        #expect(repository.fetchById(id: note.id)?.title == "Original")
        #expect(repository.fetchLinks(noteId: note.id) == [link])
    }

    @Test func deleteNote_keepsSharedDocumentAndOtherNoteBinding() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let doc = document(UUID())
        #expect(documents.insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "First", content: "")
        let other = Note(journeyId: doc.journeyId, title: "Second", content: "")
        #expect(repository.save(
            note,
            links: [NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")],
            documentIds: [doc.id]
        ))
        #expect(repository.save(other, links: [], documentIds: [doc.id]))
        #expect(repository.delete(id: note.id))
        #expect(repository.fetchLinks(noteId: note.id).isEmpty)
        #expect(repository.fetchDocuments(noteId: note.id).isEmpty)
        #expect(repository.fetchDocuments(noteId: other.id).map(\.id) == [doc.id])
        #expect(documents.fetchById(id: doc.id) != nil)
    }

    @Test func deleteDocument_clearsAllNoteBindings() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let doc = document(UUID())
        #expect(documents.insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "First", content: "")
        let other = Note(journeyId: doc.journeyId, title: "Second", content: "")
        #expect(repository.save(note, links: [], documentIds: [doc.id]))
        #expect(repository.save(other, links: [], documentIds: [doc.id]))
        #expect(documents.delete(id: doc.id))
        #expect(repository.fetchAllDocumentAttachments().isEmpty)
        #expect(repository.fetchById(id: note.id) != nil)
        #expect(repository.fetchById(id: other.id) != nil)
    }

    @Test func moveNote_clearsDocumentsAndPreservesLinks() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let doc = document(UUID())
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Trip", content: "")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: [doc.id]))
        #expect(repository.updateJourneyId(id: note.id, newJourneyId: UUID()))
        #expect(repository.fetchDocuments(noteId: note.id).isEmpty)
        #expect(repository.fetchLinks(noteId: note.id) == [link])
    }

    @Test func moveDocument_clearsNoteBindings() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let doc = document(UUID())
        #expect(documents.insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Trip", content: "")
        #expect(repository.save(note, links: [], documentIds: [doc.id]))
        #expect(documents.updateJourneyId(id: doc.id, newJourneyId: UUID()))
        #expect(repository.fetchAllDocumentAttachments().isEmpty)
    }

    @Test func migration_preservesLegacyNoteAndIsRepeatable() throws {
        let connection = try Connection(.inMemory)
        Migration_20260118_JourneyTables(db: connection).execute()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let note = Note(
            journeyId: UUID(),
            title: "Legacy",
            content: "Original instructions",
            createdAt: Date(timeIntervalSince1970: 1_790_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_790_000_000)
        )
        #expect(repository.insert(note))
        try Migration20261027NoteAttachments(db: connection).execute()
        try Migration20261027NoteAttachments(db: connection).execute()
        #expect(repository.fetchById(id: note.id) == note)
        #expect(repository.fetchLinks(noteId: note.id).isEmpty)
    }

    @Test func deleteByJourneyId_removesOnlyThatJourneysAttachments() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let first = Note(journeyId: UUID(), title: "First", content: "")
        let second = Note(journeyId: UUID(), title: "Second", content: "")
        let firstLink = NoteLink(noteId: first.id, title: "First hotel", url: "https://example.com/first")
        let secondLink = NoteLink(noteId: second.id, title: "Second hotel", url: "https://example.com/second")
        #expect(repository.save(first, links: [firstLink], documentIds: []))
        #expect(repository.save(second, links: [secondLink], documentIds: []))
        #expect(repository.deleteByJourneyId(journeyId: first.journeyId))
        #expect(repository.fetchAllLinks() == [secondLink])
        #expect(repository.deleteAll())
        #expect(repository.fetchAllLinks().isEmpty)
    }

    @Test func deleteJourney_clearsItsNoteAttachments() throws {
        let connection = try database()
        let journeys = JourneysRepository(db: connection, tableName: "journeys")
        let journey = Journey(name: "Trip", destination: "Tokyo", startDate: Date(), endDate: Date())
        #expect(journeys.insert(journey))
        let repository = NotesRepository(db: connection, tableName: "notes")
        let note = Note(journeyId: journey.id, title: "Trip", content: "")
        let doc = document(journey.id)
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        #expect(repository.save(
            note,
            links: [NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")],
            documentIds: [doc.id]
        ))
        #expect(journeys.delete(id: journey.id))
        #expect(repository.fetchAllLinks().isEmpty)
        #expect(repository.fetchAllDocumentAttachments().isEmpty)
    }

    @Test func legacyUpdate_preservesNoteAttachments() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        var note = Note(journeyId: UUID(), title: "Trip", content: "")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: []))
        note.content = "Updated text"
        #expect(repository.update(note))
        #expect(repository.fetchLinks(noteId: note.id) == [link])
    }
}
extension NotesPersistenceTests {
    @Test func loadAttachments_whenAnotherConnectionLocksDatabase_preservesAttachmentsForRetry() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("notes.sqlite").path
        let connection = try Connection(path)
        Migration_20260118_JourneyTables(db: connection).execute()
        Migration_20260119_DocumentFilePath(db: connection).execute()
        try Migration20261027NoteAttachments(db: connection).execute()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let doc = document(UUID())
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Arrival", content: "Instructions")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: [doc.id]))
        let writer = try Connection(path)
        do {
            try writer.execute("BEGIN EXCLUSIVE")
            defer { try? writer.execute("ROLLBACK") }
            #expect(throws: (any Error).self) {
                try repository.loadAttachments(noteId: note.id)
            }
        }
        let restored = try repository.loadAttachments(noteId: note.id)
        #expect(restored.links == [link])
        #expect(restored.documents.map(\.id) == [doc.id])
        #expect(repository.fetchById(id: note.id)?.content == "Instructions")
    }

    @Test func loadAttachments_whenLinksReadFails_preservesSavedAttachmentsForRetry() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let doc = document(UUID())
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Arrival", content: "Instructions")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: [doc.id]))

        try connection.execute("ALTER TABLE note_links RENAME TO unavailable_note_links")
        #expect(throws: (any Error).self) {
            try repository.loadAttachments(noteId: note.id)
        }
        try connection.execute("ALTER TABLE unavailable_note_links RENAME TO note_links")

        let restored = try repository.loadAttachments(noteId: note.id)
        #expect(restored.links == [link])
        #expect(restored.documents.map(\.id) == [doc.id])
        #expect(repository.fetchById(id: note.id)?.content == "Instructions")
    }

    @Test(arguments: [
        ("documents", "file_name"), ("notes", "content"),
        ("note_links", "title"), ("note_documents", "document_id")
    ])
    func loadAttachments_whenRequiredColumnMissing_throwsAndAllowsRetry(tableName: String, columnName: String) throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let doc = document(UUID())
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Arrival", content: "Instructions")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: [doc.id]))
        try connection.execute("ALTER TABLE \(tableName) RENAME COLUMN \(columnName) TO unavailable_column")
        #expect(throws: (any Error).self) {
            try repository.loadAttachments(noteId: note.id)
        }
        try connection.execute("ALTER TABLE \(tableName) RENAME COLUMN unavailable_column TO \(columnName)")
        let restored = try repository.loadAttachments(noteId: note.id)
        #expect(restored.links == [link])
        #expect(restored.documents.map(\.id) == [doc.id])
        #expect(repository.fetchAllDocumentAttachments().count == 1)
    }

    @Test func loadAttachments_whenLinkIdentifierIsInvalid_throwsInsteadOfDroppingRow() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let note = Note(journeyId: UUID(), title: "Arrival", content: "Instructions")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: []))
        try connection.run("UPDATE note_links SET id = ? WHERE id = ?", "invalid-uuid", link.id.uuidString)
        #expect(throws: (any Error).self) {
            try repository.loadAttachments(noteId: note.id)
        }
        try connection.run("UPDATE note_links SET id = ? WHERE id = ?", link.id.uuidString, "invalid-uuid")
        #expect(try repository.loadAttachments(noteId: note.id).links == [link])
    }

    @Test func loadAttachments_whenNoteDoesNotExist_throws() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        #expect(throws: (any Error).self) {
            try repository.loadAttachments(noteId: UUID())
        }
    }

    @Test func loadAttachments_whenDocumentReferenceIsBroken_throwsAndKeepsBinding() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let doc = document(UUID())
        #expect(DocumentsRepository(db: connection, tableName: "documents").insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Arrival", content: "Instructions")
        #expect(repository.save(note, links: [], documentIds: [doc.id]))
        try connection.execute("DROP TRIGGER documents_delete_note_attachments")
        try connection.run("DELETE FROM documents WHERE id = ?", doc.id.uuidString)
        #expect(throws: (any Error).self) {
            try repository.loadAttachments(noteId: note.id)
        }
        #expect(repository.fetchAllDocumentAttachments().count == 1)
    }

    @Test func decodeLegacyExport_defaultsAttachmentsToAbsent() throws {
        let json = """
        {
          "metadata":{"createdAt":0,"appVersion":"2026.1.7","deviceName":"Test","databaseSchemaVersion":9},
          "userSettings":{"preferredCurrency":"USD","preferredLanguage":"en"}
        }
        """
        let export = try JSONDecoder().decode(ExportData.self, from: Data(json.utf8))
        #expect(export.noteLinks == nil)
        #expect(export.noteDocumentAttachments == nil)
    }

    @Test func exportRoundTrip_restoresLinksAndDocumentBindings() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let doc = document(UUID())
        #expect(documents.insert(doc))
        let note = Note(journeyId: doc.journeyId, title: "Trip", content: "Instructions")
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(repository.save(note, links: [link], documentIds: [doc.id]))
        let export = ExportData(
            metadata: ExportMetadata(appVersion: "2026.1.8", deviceName: "Test", databaseSchemaVersion: 10),
            userSettings: ExportUserSettings(currency: .usd, language: .en),
            documents: documents.fetchAll(), notes: repository.fetchAll(),
            noteLinks: repository.fetchAllLinks(), noteDocumentAttachments: repository.fetchAllDocumentAttachments()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(ExportData.self, from: encoder.encode(export))
        let otherDB = try database()
        let otherDocuments = DocumentsRepository(db: otherDB, tableName: "documents")
        let otherNotes = NotesRepository(db: otherDB, tableName: "notes")
        for doc in restored.documents ?? [] {
            #expect(otherDocuments.insert(doc))
        }
        for note in restored.notes ?? [] {
            #expect(otherNotes.insert(note))
        }
        try otherNotes.restoreAttachments(
            links: restored.noteLinks ?? [],
            documentAttachments: restored.noteDocumentAttachments ?? []
        )
        #expect(otherNotes.fetchLinks(noteId: note.id) == [link])
        #expect(otherNotes.fetchDocuments(noteId: note.id).map(\.id) == [doc.id])
    }

    @Test func documentWithoutCustomName_insertsAndUpdatesUsingFilename() throws {
        let connection = try database()
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        var doc = Document(journeyId: UUID(), fileType: .pdf, fileName: "booking.pdf", fileSize: 128)
        #expect(documents.insert(doc))
        #expect(documents.fetchById(id: doc.id)?.displayName == "booking.pdf")
        doc.name = "Named"
        #expect(documents.update(doc))
        doc.name = nil
        #expect(documents.update(doc))
        #expect(documents.fetchById(id: doc.id)?.displayName == "booking.pdf")
    }

    @Test func restoreAttachments_withInvalidReference_rollsBackAllRows() throws {
        let connection = try database()
        let repository = NotesRepository(db: connection, tableName: "notes")
        let note = Note(journeyId: UUID(), title: "Trip", content: "")
        #expect(repository.insert(note))
        let link = NoteLink(noteId: note.id, title: "Hotel", url: "https://example.com")
        #expect(throws: (any Error).self) {
            try repository.restoreAttachments(
                links: [link],
                documentAttachments: [NoteDocumentAttachment(noteId: note.id, documentId: UUID())]
            )
        }
        #expect(repository.fetchAllLinks().isEmpty)
        #expect(repository.fetchAllDocumentAttachments().isEmpty)
    }
}
