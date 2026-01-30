import Foundation
import os
import SQLite

class IdeasRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let titleColumn = Expression<String>("title")
    private let descriptionColumn = Expression<String?>("description")
    private let urlColumn = Expression<String?>("url")
    private let isDoneColumn = Expression<Bool>("is_done")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "IdeasRepository")
    }

    func fetchAll() -> [Idea] {
        var ideas: [Idea] = []

        do {
            // Sort: not done first, then by updatedAt desc
            for row in try db.prepare(table.order(isDoneColumn.asc, updatedAtColumn.desc)) {
                if let idea = mapRowToIdea(row) {
                    ideas.append(idea)
                }
            }
        } catch {
            logger.error("Failed to fetch all ideas: \(error)")
        }

        return ideas
    }

    func fetchByJourneyId(journeyId: UUID) -> [Idea] {
        var ideas: [Idea] = []

        do {
            let query = table
                .filter(journeyIdColumn == journeyId.uuidString)
                .order(isDoneColumn.asc, updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let idea = mapRowToIdea(row) {
                    ideas.append(idea)
                }
            }
        } catch {
            logger.error("Failed to fetch ideas for journey \(journeyId): \(error)")
        }

        return ideas
    }

    func fetchById(id: UUID) -> Idea? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToIdea(row)
            }
        } catch {
            logger.error("Failed to fetch idea by id \(id): \(error)")
        }
        return nil
    }

    func fetchPending(journeyId: UUID) -> [Idea] {
        var ideas: [Idea] = []

        do {
            let query = table
                .filter(journeyIdColumn == journeyId.uuidString && isDoneColumn == false)
                .order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let idea = mapRowToIdea(row) {
                    ideas.append(idea)
                }
            }
        } catch {
            logger.error("Failed to fetch pending ideas: \(error)")
        }

        return ideas
    }

    func fetchDone(journeyId: UUID) -> [Idea] {
        var ideas: [Idea] = []

        do {
            let query = table
                .filter(journeyIdColumn == journeyId.uuidString && isDoneColumn == true)
                .order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let idea = mapRowToIdea(row) {
                    ideas.append(idea)
                }
            }
        } catch {
            logger.error("Failed to fetch done ideas: \(error)")
        }

        return ideas
    }

    func insert(_ idea: Idea) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- idea.id.uuidString,
                journeyIdColumn <- idea.journeyId.uuidString,
                titleColumn <- idea.title,
                descriptionColumn <- idea.description,
                urlColumn <- idea.url,
                isDoneColumn <- idea.isDone,
                createdAtColumn <- idea.createdAt,
                updatedAtColumn <- idea.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted idea: \(idea.id)")
            return true
        } catch {
            logger.error("Failed to insert idea: \(error)")
            return false
        }
    }

    func update(_ idea: Idea) -> Bool {
        let record = table.filter(idColumn == idea.id.uuidString)

        do {
            try db.run(record.update(
                titleColumn <- idea.title,
                descriptionColumn <- idea.description,
                urlColumn <- idea.url,
                isDoneColumn <- idea.isDone,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated idea: \(idea.id)")
            return true
        } catch {
            logger.error("Failed to update idea: \(error)")
            return false
        }
    }

    func toggleDone(id: UUID) -> Bool {
        guard let idea = fetchById(id: id) else {
            logger.error("Failed to toggle done status: idea not found")
            return false
        }

        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                isDoneColumn <- !idea.isDone,
                updatedAtColumn <- Date()
            ))
            logger.info("Toggled done status for idea: \(id)")
            return true
        } catch {
            logger.error("Failed to toggle done status: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted idea: \(id)")
            return true
        } catch {
            logger.error("Failed to delete idea: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted ideas for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete ideas for journey: \(error)")
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
            logger.info("Moved idea \(id) to journey \(newJourneyId)")
            return true
        } catch {
            logger.error("Failed to move idea: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all ideas")
            return true
        } catch {
            logger.error("Failed to delete all ideas: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count ideas: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count ideas for journey: \(error)")
            return 0
        }
    }

    func countDone(journeyId: UUID) -> Int {
        do {
            return try db.scalar(
                table.filter(journeyIdColumn == journeyId.uuidString && isDoneColumn == true).count
            )
        } catch {
            logger.error("Failed to count done ideas: \(error)")
            return 0
        }
    }

    private func mapRowToIdea(_ row: Row) -> Idea? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]) else {
            return nil
        }

        return Idea(
            id: id,
            journeyId: journeyId,
            title: row[titleColumn],
            description: row[descriptionColumn],
            url: row[urlColumn],
            isDone: row[isDoneColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
