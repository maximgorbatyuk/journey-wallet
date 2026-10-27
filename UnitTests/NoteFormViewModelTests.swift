import Foundation
@testable import JourneyWallet_Dev
import SQLite
import Testing

@MainActor
struct NoteFormViewModelTests {
    private func database() throws -> Connection {
        let connection = try Connection(.inMemory)
        Migration_20260118_JourneyTables(db: connection).execute()
        Migration_20260119_DocumentFilePath(db: connection).execute()
        try Migration20261027NoteAttachments(db: connection).execute()
        return connection
    }

    private func repositories() throws -> (NotesRepository, DocumentsRepository) {
        let connection = try database()
        return (
            NotesRepository(db: connection, tableName: "notes"),
            DocumentsRepository(db: connection, tableName: "documents")
        )
    }

    @Test(arguments: [
        (" maps.google.com/?q=hotel ", "https://maps.google.com/?q=hotel"),
        ("https://www.instagram.com/example/", "https://www.instagram.com/example/"),
        ("http://example.com/path", "http://example.com/path")
    ])
    func normalizeURL_withWebAddress_preservesDestination(input: String, expected: String) {
        #expect(NoteLinkURL.normalized(input)?.absoluteString == expected)
    }

    @Test(arguments: [
        "",
        "   ",
        "javascript:alert(1)",
        "file:///tmp/file",
        "https://",
        "https://bad host.com",
        "https://bad%20host.com",
        "mailto:test@example.com"
    ])
    func normalizeURL_withUnsupportedAddress_rejectsInput(input: String) {
        #expect(NoteLinkURL.normalized(input) == nil)
    }

    @Test func save_withEmptyDraft_keepsDatabaseEmpty() throws {
        let (notes, documents) = try repositories()
        let model = NoteFormViewModel(
            journeyId: UUID(),
            mode: .add,
            notesRepository: notes,
            documentsRepository: documents
        )
        #expect(model.save() == nil)
        #expect(model.errorMessage != nil)
        #expect(notes.fetchAll().isEmpty)
    }

    @Test func save_afterAttachmentReadFailure_requiresRetryAndPreservesDraft() throws {
        let connection = try database()
        let notes = NotesRepository(db: connection, tableName: "notes")
        let documents = DocumentsRepository(db: connection, tableName: "documents")
        let journeyId = UUID()
        let document = Document(
            journeyId: journeyId, name: "Booking", fileType: .pdf, fileName: "booking.pdf", fileSize: 32
        )
        #expect(documents.insert(document))
        let note = Note(journeyId: journeyId, title: "Arrival", content: "Saved instructions")
        let link = NoteLink(noteId: note.id, title: "Entrance", url: "https://example.com/entrance")
        #expect(notes.save(note, links: [link], documentIds: [document.id]))
        try connection.run("ALTER TABLE note_links RENAME TO unavailable_note_links")
        let model = NoteFormViewModel(
            journeyId: journeyId, mode: .edit(note), notesRepository: notes, documentsRepository: documents
        )
        #expect(!model.attachmentsLoaded)
        #expect(model.errorMessage == L("note.error.load"))
        try connection.run("ALTER TABLE unavailable_note_links RENAME TO note_links")

        model.title = "Updated arrival"
        model.content = "Edited instructions"
        #expect(model.save() == nil)
        #expect(notes.fetchById(id: note.id)?.title == "Arrival")
        #expect(notes.fetchLinks(noteId: note.id) == [link])
        #expect(notes.fetchDocuments(noteId: note.id).map(\.id) == [document.id])

        model.retryLoadingAttachments()
        #expect(model.attachmentsLoaded)
        #expect(model.errorMessage == nil)
        #expect(model.title == "Updated arrival")
        #expect(model.content == "Edited instructions")
        #expect(model.save()?.title == "Updated arrival")
        #expect(notes.fetchLinks(noteId: note.id) == [link])
        #expect(notes.fetchDocuments(noteId: note.id).map(\.id) == [document.id])
    }

    @Test func save_withNamedLinkOnly_persistsNormalizedLink() throws {
        let (notes, documents) = try repositories()
        let model = NoteFormViewModel(
            journeyId: UUID(),
            mode: .add,
            notesRepository: notes,
            documentsRepository: documents
        )
        #expect(model.upsertLink(id: nil, title: " Entrance ", url: "maps.google.com/?q=hotel"))
        let saved = try #require(model.save())
        let links = notes.fetchLinks(noteId: saved.id)
        #expect(links.count == 1)
        #expect(links.first?.title == "Entrance")
        #expect(links.first?.url == "https://maps.google.com/?q=hotel")
    }

    @Test func editLink_changesCaptionAndDestinationWithoutDuplicating() throws {
        let (notes, documents) = try repositories()
        let model = NoteFormViewModel(
            journeyId: UUID(),
            mode: .add,
            notesRepository: notes,
            documentsRepository: documents
        )
        #expect(model.upsertLink(id: nil, title: "Hotel", url: "https://example.com"))
        let id = try #require(model.links.first?.id)
        #expect(model.upsertLink(id: id, title: "Entrance", url: "https://example.com/entrance"))
        #expect(model.links.count == 1)
        #expect(model.links.first?.id == id)
        #expect(model.links.first?.title == "Entrance")
        #expect(!model.upsertLink(id: id, title: " ", url: "https://example.com"))
        #expect(model.links.first?.title == "Entrance")
    }

    @Test func cancelDraft_doesNotPersistLinksOrDetachExistingDocument() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        let document = Document(
            journeyId: journeyId,
            name: "Booking",
            fileType: .pdf,
            fileName: "booking.pdf",
            fileSize: 32
        )
        #expect(documents.insert(document))
        let note = Note(journeyId: journeyId, title: "Saved", content: "Instructions")
        #expect(notes.save(note, links: [], documentIds: [document.id]))
        let model = NoteFormViewModel(
            journeyId: journeyId,
            mode: .edit(note),
            notesRepository: notes,
            documentsRepository: documents
        )
        model.title = "Discarded"
        model.removeDocument(id: document.id)
        #expect(model.upsertLink(id: nil, title: "Hotel", url: "https://example.com"))
        #expect(notes.fetchById(id: note.id)?.title == "Saved")
        #expect(notes.fetchDocuments(noteId: note.id).map(\.id) == [document.id])
        #expect(notes.fetchLinks(noteId: note.id).isEmpty)
    }

    @Test func attachImportedDocuments_deduplicatesAndRejectsOtherJourney() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        let document = Document(
            journeyId: journeyId,
            name: "Booking",
            fileType: .pdf,
            fileName: "booking.pdf",
            fileSize: 32
        )
        let foreign = Document(journeyId: UUID(), name: "Other", fileType: .pdf, fileName: "other.pdf", fileSize: 32)
        #expect(documents.insert(document))
        #expect(documents.insert(foreign))
        let model = NoteFormViewModel(
            journeyId: journeyId,
            mode: .add,
            notesRepository: notes,
            documentsRepository: documents
        )
        model.attachImportedDocuments([document, document, foreign])
        #expect(model.documents.map(\.id) == [document.id])
        let saved = try #require(model.save())
        #expect(notes.fetchDocuments(noteId: saved.id).map(\.id) == [document.id])
    }

    @Test func save_whenDocumentRemoved_keepsDraftAndReportsFailure() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        let document = Document(
            journeyId: journeyId,
            name: "Booking",
            fileType: .pdf,
            fileName: "booking.pdf",
            fileSize: 32
        )
        #expect(documents.insert(document))
        let model = NoteFormViewModel(
            journeyId: journeyId,
            mode: .add,
            notesRepository: notes,
            documentsRepository: documents
        )
        model.title = "Arrival"
        model.attachImportedDocuments([document])
        #expect(documents.delete(id: document.id))
        #expect(model.save() == nil)
        #expect(model.title == "Arrival")
        #expect(model.documents.map(\.id) == [document.id])
        #expect(model.errorMessage != nil)
        #expect(notes.fetchAll().isEmpty)
    }

}

extension NoteFormViewModelTests {
    @Test func selectDocuments_withDeselect_keepsPersistedBindingsUntilSave() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        let first = Document(
            journeyId: journeyId,
            name: "Booking",
            fileType: .pdf,
            fileName: "booking.pdf",
            fileSize: 32
        )
        let second = Document(
            journeyId: journeyId,
            name: "Tickets",
            fileType: .pdf,
            fileName: "tickets.pdf",
            fileSize: 32
        )
        let third = Document(journeyId: journeyId, name: "Map", fileType: .pdf, fileName: "map.pdf", fileSize: 32)
        for document in [first, second, third] {
            #expect(documents.insert(document))
        }
        let note = Note(journeyId: journeyId, title: "Arrival", content: "Instructions")
        #expect(notes.save(note, links: [], documentIds: [first.id, second.id]))
        let model = NoteFormViewModel(
            journeyId: journeyId,
            mode: .edit(note),
            notesRepository: notes,
            documentsRepository: documents
        )

        model.selectDocuments(ids: [second.id, third.id])
        #expect(model.documents.map(\.id) == [second.id, third.id])
        model.selectDocuments(ids: [third.id])
        #expect(model.documents.map(\.id) == [third.id])
        #expect(notes.fetchDocuments(noteId: note.id).map(\.id) == [first.id, second.id])

        let reopened = NoteFormViewModel(
            journeyId: journeyId,
            mode: .edit(note),
            notesRepository: notes,
            documentsRepository: documents
        )
        #expect(reopened.documents.map(\.id) == [first.id, second.id])
    }

    @Test func save_withExistingDocumentSelection_replacesBindingsWithoutDeletingDocuments() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        let first = Document(
            journeyId: journeyId,
            name: "Booking",
            fileType: .pdf,
            fileName: "booking.pdf",
            fileSize: 32
        )
        let second = Document(
            journeyId: journeyId,
            name: "Tickets",
            fileType: .pdf,
            fileName: "tickets.pdf",
            fileSize: 32
        )
        #expect(documents.insert(first))
        #expect(documents.insert(second))
        let note = Note(journeyId: journeyId, title: "Arrival", content: "Instructions")
        #expect(notes.save(note, links: [], documentIds: [first.id]))
        let model = NoteFormViewModel(
            journeyId: journeyId,
            mode: .edit(note),
            notesRepository: notes,
            documentsRepository: documents
        )

        model.selectDocuments(ids: [first.id, second.id])
        model.selectDocuments(ids: [second.id])
        #expect(model.save()?.id == note.id)
        #expect(notes.fetchDocuments(noteId: note.id).map(\.id) == [second.id])
        #expect(documents.fetchById(id: first.id) != nil)
    }

    @Test func reload_afterDocumentRenameAndDelete_refreshesCards() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        var document = Document(
            journeyId: journeyId,
            name: "Booking",
            fileType: .pdf,
            fileName: "booking.pdf",
            fileSize: 32
        )
        #expect(documents.insert(document))
        let note = Note(journeyId: journeyId, title: "Arrival", content: "Instructions")
        #expect(notes.save(note, links: [], documentIds: [document.id]))
        let model = NoteDetailViewModel(noteId: note.id, notesRepository: notes)
        #expect(model.documents.first?.displayName == "Booking")

        document.name = "Hotel confirmation"
        #expect(documents.update(document))
        model.reload()
        #expect(model.documents.first?.displayName == "Hotel confirmation")
        #expect(documents.delete(id: document.id))
        model.reload()
        #expect(model.documents.isEmpty)
        #expect(model.note?.id == note.id)
    }

    @Test func canPreview_whenFileMissing_reportsErrorWithoutRemovingCard() throws {
        let (notes, documents) = try repositories()
        let journeyId = UUID()
        let document = Document(
            journeyId: journeyId,
            name: "Missing",
            fileType: .pdf,
            fileName: "missing.pdf",
            fileSize: 32
        )
        defer { _ = DocumentService.shared.deleteAllDocuments(journeyId: journeyId) }
        #expect(documents.insert(document))
        let note = Note(journeyId: journeyId, title: "Arrival", content: "Instructions")
        #expect(notes.save(note, links: [], documentIds: [document.id]))
        let model = NoteDetailViewModel(noteId: note.id, notesRepository: notes)

        #expect(!model.canPreview(document))
        #expect(model.errorMessage == L("note.document.missing"))
        #expect(model.documents.map(\.id) == [document.id])
    }
}
