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
