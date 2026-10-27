import Foundation
import SQLite
import os

class NotesRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let titleColumn = Expression<String>("title")
    private let contentColumn = Expression<String>("content")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")
    private let linksTable = Table("note_links")
    private let attachmentsTable = Table("note_documents")
    private let noteIdColumn = Expression<String>("note_id")
    private let documentIdColumn = Expression<String>("document_id")
    private let urlColumn = Expression<String>("url")
    private let sortOrderColumn = Expression<Int>("sort_order")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "NotesRepository")
    }

    func fetchAll() -> [Note] {
        var notes: [Note] = []

        do {
            for row in try db.prepare(table.order(updatedAtColumn.desc)) {
                if let note = mapRowToNote(row) {
                    notes.append(note)
                }
            }
        } catch {
            logger.error("Failed to fetch all notes: \(error)")
        }

        return notes
    }

    func fetchByJourneyId(journeyId: UUID) -> [Note] {
        var notes: [Note] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let note = mapRowToNote(row) {
                    notes.append(note)
                }
            }
        } catch {
            logger.error("Failed to fetch notes for journey \(journeyId): \(error)")
        }

        return notes
    }

    func fetchById(id: UUID) -> Note? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToNote(row)
            }
        } catch {
            logger.error("Failed to fetch note by id \(id): \(error)")
        }
        return nil
    }

    func search(query searchQuery: String) -> [Note] {
        var notes: [Note] = []
        let searchPattern = "%\(searchQuery)%"

        do {
            let query = table.filter(
                titleColumn.like(searchPattern) || contentColumn.like(searchPattern)
            ).order(updatedAtColumn.desc)

            for row in try db.prepare(query) {
                if let note = mapRowToNote(row) {
                    notes.append(note)
                }
            }
        } catch {
            logger.error("Failed to search notes: \(error)")
        }

        return notes
    }

    func insert(_ note: Note) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- note.id.uuidString,
                journeyIdColumn <- note.journeyId.uuidString,
                titleColumn <- note.title,
                contentColumn <- note.content,
                createdAtColumn <- note.createdAt,
                updatedAtColumn <- note.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted note: \(note.id)")
            return true
        } catch {
            logger.error("Failed to insert note: \(error)")
            return false
        }
    }

    func update(_ note: Note) -> Bool {
        let record = table.filter(idColumn == note.id.uuidString)

        do {
            try db.run(record.update(
                titleColumn <- note.title,
                contentColumn <- note.content,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated note: \(note.id)")
            return true
        } catch {
            logger.error("Failed to update note: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted note: \(id)")
            return true
        } catch {
            logger.error("Failed to delete note: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted notes for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete notes for journey: \(error)")
            return false
        }
    }

    func updateJourneyId(id: UUID, newJourneyId: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                journeyIdColumn <- newJourneyId.uuidString,
                updatedAtColumn <- Date()
            ))
            logger.info("Moved note \(id) to journey \(newJourneyId)")
            return true
        } catch {
            logger.error("Failed to move note: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all notes")
            return true
        } catch {
            logger.error("Failed to delete all notes: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count notes: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count notes for journey: \(error)")
            return 0
        }
    }
}

extension NotesRepository {
    func loadAttachments(noteId: UUID) throws -> (links: [NoteLink], documents: [Document]) {
        var attachments: (links: [NoteLink], documents: [Document]) = ([], [])
        try db.transaction(.deferred) {
            let query = table.select(
                table[idColumn], table[journeyIdColumn], table[titleColumn],
                table[contentColumn], table[createdAtColumn], table[updatedAtColumn]
            ).filter(table[idColumn] == noteId.uuidString)
            guard let row = try db.pluck(query), let note = mapRowToNote(row) else {
                throw AttachmentError.invalidReference
            }
            let links = try loadLinks(
                linksTable.filter(linksTable[noteIdColumn] == noteId.uuidString)
                    .order(linksTable[sortOrderColumn].asc, linksTable[idColumn].asc)
            )
            let documents = try loadDocuments(noteId: noteId)
            guard documents.allSatisfy({ $0.journeyId == note.journeyId }) else {
                throw AttachmentError.invalidReference
            }
            attachments = (links, documents)
        }
        return attachments
    }

    func fetchLinks(noteId: UUID) -> [NoteLink] {
        readLinks(linksTable.filter(linksTable[noteIdColumn] == noteId.uuidString)
            .order(linksTable[sortOrderColumn].asc, linksTable[idColumn].asc))
    }

    func fetchAllLinks() -> [NoteLink] {
        readLinks(linksTable.order(
            linksTable[noteIdColumn].asc, linksTable[sortOrderColumn].asc, linksTable[idColumn].asc
        ))
    }

    func fetchDocuments(noteId: UUID) -> [Document] {
        do {
            return try loadDocuments(noteId: noteId)
        } catch {
            logger.error("Failed to fetch note documents: \(error)")
            return []
        }
    }

    func fetchAllDocumentAttachments() -> [NoteDocumentAttachment] {
        do {
            let query = attachmentsTable.select(
                attachmentsTable[noteIdColumn], attachmentsTable[documentIdColumn], attachmentsTable[sortOrderColumn]
            ).order(attachmentsTable[noteIdColumn].asc, attachmentsTable[sortOrderColumn].asc)
            return try db.prepareRowIterator(query).map { row in
                guard let noteId = UUID(uuidString: row[noteIdColumn]),
                      let documentId = UUID(uuidString: row[documentIdColumn]) else {
                    throw AttachmentError.invalidReference
                }
                return NoteDocumentAttachment(noteId: noteId, documentId: documentId, sortOrder: row[sortOrderColumn])
            }
        } catch {
            logger.error("Failed to fetch note document attachments: \(error)")
            return []
        }
    }

    func save(_ note: Note, links: [NoteLink], documentIds: [UUID]) -> Bool {
        do {
            try db.transaction(.immediate) {
                if let existing = fetchById(id: note.id) {
                    guard existing.journeyId == note.journeyId, update(note) else {
                        throw AttachmentError.invalidReference
                    }
                } else if !insert(note) {
                    throw AttachmentError.saveFailed
                }

                try db.run(linksTable.filter(noteIdColumn == note.id.uuidString).delete())
                try db.run(attachmentsTable.filter(noteIdColumn == note.id.uuidString).delete())
                for link in links {
                    guard link.noteId == note.id else { throw AttachmentError.invalidReference }
                    try insertLink(link)
                }

                var attachedIds = Set<UUID>()
                for id in documentIds where attachedIds.insert(id).inserted {
                    try insertAttachment(NoteDocumentAttachment(
                        noteId: note.id, documentId: id, sortOrder: attachedIds.count - 1
                    ))
                }
            }
            return true
        } catch {
            logger.error("Failed to save note and attachments: \(error)")
            return false
        }
    }

    func restoreAttachments(links: [NoteLink], documentAttachments: [NoteDocumentAttachment]) throws {
        try db.transaction(.immediate) {
            for link in links {
                try insertLink(link)
            }
            for attachment in documentAttachments {
                try insertAttachment(attachment)
            }
        }
    }

    private func readLinks(_ query: Table) -> [NoteLink] {
        do {
            return try loadLinks(query)
        } catch {
            logger.error("Failed to fetch note links: \(error)")
            return []
        }
    }

    private func loadLinks(_ query: Table) throws -> [NoteLink] {
        let columns = query.select(
            linksTable[idColumn], linksTable[noteIdColumn], linksTable[titleColumn],
            linksTable[urlColumn], linksTable[sortOrderColumn]
        )
        return try db.prepareRowIterator(columns).map { row in
            guard let id = UUID(uuidString: row[idColumn]),
                  let noteId = UUID(uuidString: row[noteIdColumn]) else {
                throw AttachmentError.invalidReference
            }
            return NoteLink(
                id: id, noteId: noteId, title: row[titleColumn],
                url: row[urlColumn], sortOrder: row[sortOrderColumn]
            )
        }
    }

    private func loadDocuments(noteId: UUID) throws -> [Document] {
        let repository = DocumentsRepository(db: db, tableName: DatabaseManager.DocumentsTableName)
        let query = attachmentsTable.select(
            attachmentsTable[noteIdColumn], attachmentsTable[documentIdColumn], attachmentsTable[sortOrderColumn]
        ).filter(attachmentsTable[noteIdColumn] == noteId.uuidString).order(attachmentsTable[sortOrderColumn].asc)
        return try db.prepareRowIterator(query).map { row in
            guard let id = UUID(uuidString: row[documentIdColumn]),
                  let document = try repository.loadById(id: id) else {
                throw AttachmentError.invalidReference
            }
            return document
        }
    }

    private func insertLink(_ link: NoteLink) throws {
        guard !link.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URLComponents(string: link.url),
              let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty else {
            throw AttachmentError.invalidLink
        }
        try db.run(linksTable.insert(
            idColumn <- link.id.uuidString,
            noteIdColumn <- link.noteId.uuidString,
            titleColumn <- link.title,
            urlColumn <- link.url,
            sortOrderColumn <- link.sortOrder
        ))
    }

    private func insertAttachment(_ attachment: NoteDocumentAttachment) throws {
        try db.run(attachmentsTable.insert(
            noteIdColumn <- attachment.noteId.uuidString,
            documentIdColumn <- attachment.documentId.uuidString,
            sortOrderColumn <- attachment.sortOrder
        ))
    }

    private enum AttachmentError: Error {
        case invalidReference
        case invalidLink
        case saveFailed
    }

    private func mapRowToNote(_ row: Row) -> Note? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]) else {
            return nil
        }

        return Note(
            id: id,
            journeyId: journeyId,
            title: row[titleColumn],
            content: row[contentColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
