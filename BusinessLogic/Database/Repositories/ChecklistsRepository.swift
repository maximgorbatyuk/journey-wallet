import Foundation
import SQLite
import os

class ChecklistsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let nameColumn = Expression<String>("name")
    private let sortingOrderColumn = Expression<Int>("sorting_order")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ChecklistsRepository")
    }

    func fetchAll() -> [Checklist] {
        var checklists: [Checklist] = []

        do {
            for row in try db.prepare(table.order(sortingOrderColumn.asc)) {
                if let checklist = mapRowToChecklist(row) {
                    checklists.append(checklist)
                }
            }
        } catch {
            logger.error("Failed to fetch all checklists: \(error)")
        }

        return checklists
    }

    func fetchByJourneyId(journeyId: UUID) -> [Checklist] {
        var checklists: [Checklist] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(sortingOrderColumn.asc)
            for row in try db.prepare(query) {
                if let checklist = mapRowToChecklist(row) {
                    checklists.append(checklist)
                }
            }
        } catch {
            logger.error("Failed to fetch checklists for journey \(journeyId): \(error)")
        }

        return checklists
    }

    func fetchById(id: UUID) -> Checklist? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToChecklist(row)
            }
        } catch {
            logger.error("Failed to fetch checklist by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ checklist: Checklist) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- checklist.id.uuidString,
                journeyIdColumn <- checklist.journeyId.uuidString,
                nameColumn <- checklist.name,
                sortingOrderColumn <- checklist.sortingOrder,
                createdAtColumn <- checklist.createdAt,
                updatedAtColumn <- checklist.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted checklist: \(checklist.id)")
            return true
        } catch {
            logger.error("Failed to insert checklist: \(error)")
            return false
        }
    }

    func update(_ checklist: Checklist) -> Bool {
        let record = table.filter(idColumn == checklist.id.uuidString)

        do {
            try db.run(record.update(
                nameColumn <- checklist.name,
                sortingOrderColumn <- checklist.sortingOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated checklist: \(checklist.id)")
            return true
        } catch {
            logger.error("Failed to update checklist: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted checklist: \(id)")
            return true
        } catch {
            logger.error("Failed to delete checklist: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted checklists for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete checklists for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all checklists")
            return true
        } catch {
            logger.error("Failed to delete all checklists: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count checklists: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count checklists for journey: \(error)")
            return 0
        }
    }

    func getNextSortingOrder(journeyId: UUID) -> Int {
        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString)
            if let maxOrder = try db.scalar(query.select(sortingOrderColumn.max)) {
                return maxOrder + 1
            }
        } catch {
            logger.error("Failed to get next sorting order: \(error)")
        }
        return 0
    }

    func updateSortingOrders(_ checklists: [Checklist]) -> Bool {
        do {
            try db.transaction {
                for checklist in checklists {
                    let record = table.filter(idColumn == checklist.id.uuidString)
                    try db.run(record.update(
                        sortingOrderColumn <- checklist.sortingOrder,
                        updatedAtColumn <- Date()
                    ))
                }
            }
            logger.info("Updated sorting orders for \(checklists.count) checklists")
            return true
        } catch {
            logger.error("Failed to update sorting orders: \(error)")
            return false
        }
    }

    private func mapRowToChecklist(_ row: Row) -> Checklist? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]) else {
            return nil
        }

        return Checklist(
            id: id,
            journeyId: journeyId,
            name: row[nameColumn],
            sortingOrder: row[sortingOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
