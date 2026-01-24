import Foundation
import SQLite
import os

class ChecklistItemsRepository {
    private let table: Table
    private let checklistsTable: Table

    private let idColumn = Expression<String>("id")
    private let checklistIdColumn = Expression<String>("checklist_id")
    private let nameColumn = Expression<String>("name")
    private let isCheckedColumn = Expression<Bool>("is_checked")
    private let sortingOrderColumn = Expression<Int>("sorting_order")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let checklistJourneyIdColumn = Expression<String>("journey_id")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, checklistsTableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.checklistsTable = Table(checklistsTableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ChecklistItemsRepository")
    }

    func fetchAll() -> [ChecklistItem] {
        var items: [ChecklistItem] = []

        do {
            for row in try db.prepare(table.order(sortingOrderColumn.asc)) {
                if let item = mapRowToChecklistItem(row) {
                    items.append(item)
                }
            }
        } catch {
            logger.error("Failed to fetch all checklist items: \(error)")
        }

        return items
    }

    func fetchByChecklistId(checklistId: UUID) -> [ChecklistItem] {
        var items: [ChecklistItem] = []

        do {
            let query = table.filter(checklistIdColumn == checklistId.uuidString).order(sortingOrderColumn.asc)
            for row in try db.prepare(query) {
                if let item = mapRowToChecklistItem(row) {
                    items.append(item)
                }
            }
        } catch {
            logger.error("Failed to fetch checklist items for checklist \(checklistId): \(error)")
        }

        return items
    }

    func fetchById(id: UUID) -> ChecklistItem? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToChecklistItem(row)
            }
        } catch {
            logger.error("Failed to fetch checklist item by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ item: ChecklistItem) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- item.id.uuidString,
                checklistIdColumn <- item.checklistId.uuidString,
                nameColumn <- item.name,
                isCheckedColumn <- item.isChecked,
                sortingOrderColumn <- item.sortingOrder,
                createdAtColumn <- item.createdAt,
                updatedAtColumn <- item.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted checklist item: \(item.id)")
            return true
        } catch {
            logger.error("Failed to insert checklist item: \(error)")
            return false
        }
    }

    func update(_ item: ChecklistItem) -> Bool {
        let record = table.filter(idColumn == item.id.uuidString)

        do {
            try db.run(record.update(
                nameColumn <- item.name,
                isCheckedColumn <- item.isChecked,
                sortingOrderColumn <- item.sortingOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated checklist item: \(item.id)")
            return true
        } catch {
            logger.error("Failed to update checklist item: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted checklist item: \(id)")
            return true
        } catch {
            logger.error("Failed to delete checklist item: \(error)")
            return false
        }
    }

    func deleteByChecklistId(checklistId: UUID) -> Bool {
        let records = table.filter(checklistIdColumn == checklistId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted checklist items for checklist: \(checklistId)")
            return true
        } catch {
            logger.error("Failed to delete checklist items for checklist: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all checklist items")
            return true
        } catch {
            logger.error("Failed to delete all checklist items: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        do {
            // Delete items where checklist belongs to the journey
            let query = table.join(
                checklistsTable,
                on: checklistIdColumn == checklistsTable[Expression<String>("id")]
            ).filter(checklistsTable[checklistJourneyIdColumn] == journeyId.uuidString)

            // Get all checklist IDs for this journey first
            let checklistIds = try db.prepare(
                checklistsTable.filter(checklistJourneyIdColumn == journeyId.uuidString).select(Expression<String>("id"))
            ).map { $0[Expression<String>("id")] }

            // Delete items for each checklist
            for checklistId in checklistIds {
                let records = table.filter(checklistIdColumn == checklistId)
                try db.run(records.delete())
            }

            logger.info("Deleted checklist items for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete checklist items for journey: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count checklist items: \(error)")
            return 0
        }
    }

    func countByChecklistId(checklistId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(checklistIdColumn == checklistId.uuidString).count)
        } catch {
            logger.error("Failed to count checklist items for checklist: \(error)")
            return 0
        }
    }

    func countCheckedByChecklistId(checklistId: UUID) -> Int {
        do {
            let query = table.filter(checklistIdColumn == checklistId.uuidString && isCheckedColumn == true)
            return try db.scalar(query.count)
        } catch {
            logger.error("Failed to count checked items for checklist: \(error)")
            return 0
        }
    }

    func toggleChecked(id: UUID) -> Bool {
        guard let item = fetchById(id: id) else {
            return false
        }

        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                isCheckedColumn <- !item.isChecked,
                updatedAtColumn <- Date()
            ))
            logger.info("Toggled checklist item: \(id)")
            return true
        } catch {
            logger.error("Failed to toggle checklist item: \(error)")
            return false
        }
    }

    func countTotalByJourneyId(journeyId: UUID) -> Int {
        do {
            let query = table.join(
                checklistsTable,
                on: checklistIdColumn == checklistsTable[Expression<String>("id")]
            ).filter(checklistsTable[checklistJourneyIdColumn] == journeyId.uuidString)
            return try db.scalar(query.count)
        } catch {
            logger.error("Failed to count total items for journey: \(error)")
            return 0
        }
    }

    func countCheckedByJourneyId(journeyId: UUID) -> Int {
        do {
            let query = table.join(
                checklistsTable,
                on: checklistIdColumn == checklistsTable[Expression<String>("id")]
            ).filter(
                checklistsTable[checklistJourneyIdColumn] == journeyId.uuidString &&
                isCheckedColumn == true
            )
            return try db.scalar(query.count)
        } catch {
            logger.error("Failed to count checked items for journey: \(error)")
            return 0
        }
    }

    func getNextSortingOrder(checklistId: UUID) -> Int {
        do {
            let query = table.filter(checklistIdColumn == checklistId.uuidString)
            if let maxOrder = try db.scalar(query.select(sortingOrderColumn.max)) {
                return maxOrder + 1
            }
        } catch {
            logger.error("Failed to get next sorting order: \(error)")
        }
        return 0
    }

    func updateSortingOrders(_ items: [ChecklistItem]) -> Bool {
        do {
            try db.transaction {
                for item in items {
                    let record = table.filter(idColumn == item.id.uuidString)
                    try db.run(record.update(
                        sortingOrderColumn <- item.sortingOrder,
                        updatedAtColumn <- Date()
                    ))
                }
            }
            logger.info("Updated sorting orders for \(items.count) checklist items")
            return true
        } catch {
            logger.error("Failed to update sorting orders: \(error)")
            return false
        }
    }

    private func mapRowToChecklistItem(_ row: Row) -> ChecklistItem? {
        guard let id = UUID(uuidString: row[idColumn]),
              let checklistId = UUID(uuidString: row[checklistIdColumn]) else {
            return nil
        }

        return ChecklistItem(
            id: id,
            checklistId: checklistId,
            name: row[nameColumn],
            isChecked: row[isCheckedColumn],
            sortingOrder: row[sortingOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
