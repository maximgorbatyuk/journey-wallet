import Foundation
import SQLite
import os

class Migration_20260124_Checklists {

    private let migrationName = "20260124_Checklists"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try createChecklistsTable(logger: logger)
            try createChecklistItemsTable(logger: logger)

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func createChecklistsTable(logger: Logger) throws {
        let table = Table("checklists")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let name = Expression<String>("name")
        let sortingOrder = Expression<Int>("sorting_order")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(name)
            t.column(sortingOrder, defaultValue: 0)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Checklists table created successfully")
    }

    private func createChecklistItemsTable(logger: Logger) throws {
        let table = Table("checklist_items")

        let id = Expression<String>("id")
        let checklistId = Expression<String>("checklist_id")
        let name = Expression<String>("name")
        let isChecked = Expression<Bool>("is_checked")
        let sortingOrder = Expression<Int>("sorting_order")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(checklistId)
            t.column(name)
            t.column(isChecked, defaultValue: false)
            t.column(sortingOrder, defaultValue: 0)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(checklistId, ifNotExists: true))

        logger.debug("Checklist items table created successfully")
    }
}
