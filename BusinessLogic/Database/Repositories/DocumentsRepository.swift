import Foundation
import SQLite
import os

class DocumentsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let nameColumn = Expression<String>("name")
    private let fileTypeColumn = Expression<String>("file_type")
    private let fileNameColumn = Expression<String>("file_name")
    private let fileSizeColumn = Expression<Int64>("file_size")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "DocumentsRepository")
    }

    func fetchAll() -> [Document] {
        var documents: [Document] = []

        do {
            for row in try db.prepare(table.order(createdAtColumn.desc)) {
                if let document = mapRowToDocument(row) {
                    documents.append(document)
                }
            }
        } catch {
            logger.error("Failed to fetch all documents: \(error)")
        }

        return documents
    }

    func fetchByJourneyId(journeyId: UUID) -> [Document] {
        var documents: [Document] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let document = mapRowToDocument(row) {
                    documents.append(document)
                }
            }
        } catch {
            logger.error("Failed to fetch documents for journey \(journeyId): \(error)")
        }

        return documents
    }

    func fetchById(id: UUID) -> Document? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToDocument(row)
            }
        } catch {
            logger.error("Failed to fetch document by id \(id): \(error)")
        }
        return nil
    }

    func fetchByFileType(fileType: DocumentType) -> [Document] {
        var documents: [Document] = []

        do {
            let query = table.filter(fileTypeColumn == fileType.rawValue).order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let document = mapRowToDocument(row) {
                    documents.append(document)
                }
            }
        } catch {
            logger.error("Failed to fetch documents by type \(fileType.rawValue): \(error)")
        }

        return documents
    }

    func insert(_ document: Document) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- document.id.uuidString,
                journeyIdColumn <- document.journeyId.uuidString,
                nameColumn <- document.name,
                fileTypeColumn <- document.fileType.rawValue,
                fileNameColumn <- document.fileName,
                fileSizeColumn <- document.fileSize,
                notesColumn <- document.notes,
                createdAtColumn <- document.createdAt
            )
            try db.run(insert)
            logger.info("Inserted document: \(document.id)")
            return true
        } catch {
            logger.error("Failed to insert document: \(error)")
            return false
        }
    }

    func update(_ document: Document) -> Bool {
        let record = table.filter(idColumn == document.id.uuidString)

        do {
            try db.run(record.update(
                nameColumn <- document.name,
                fileTypeColumn <- document.fileType.rawValue,
                fileNameColumn <- document.fileName,
                fileSizeColumn <- document.fileSize,
                notesColumn <- document.notes
            ))
            logger.info("Updated document: \(document.id)")
            return true
        } catch {
            logger.error("Failed to update document: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted document: \(id)")
            return true
        } catch {
            logger.error("Failed to delete document: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted documents for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete documents for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all documents")
            return true
        } catch {
            logger.error("Failed to delete all documents: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count documents: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count documents for journey: \(error)")
            return 0
        }
    }

    func totalFileSize() -> Int64 {
        do {
            return try db.scalar(table.select(fileSizeColumn.sum)) ?? 0
        } catch {
            logger.error("Failed to calculate total file size: \(error)")
            return 0
        }
    }

    func totalFileSizeByJourneyId(journeyId: UUID) -> Int64 {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).select(fileSizeColumn.sum)) ?? 0
        } catch {
            logger.error("Failed to calculate total file size for journey: \(error)")
            return 0
        }
    }

    private func mapRowToDocument(_ row: Row) -> Document? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]),
              let fileType = DocumentType(rawValue: row[fileTypeColumn]) else {
            return nil
        }

        return Document(
            id: id,
            journeyId: journeyId,
            name: row[nameColumn],
            fileType: fileType,
            fileName: row[fileNameColumn],
            fileSize: row[fileSizeColumn],
            notes: row[notesColumn],
            createdAt: row[createdAtColumn]
        )
    }
}
