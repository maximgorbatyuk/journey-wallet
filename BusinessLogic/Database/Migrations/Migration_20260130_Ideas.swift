import Foundation
import os
import SQLite

class Migration_20260130_Ideas {

    private let migrationName = "20260130_Ideas"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try createIdeasTable(logger: logger)

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func createIdeasTable(logger: Logger) throws {
        let table = Table("ideas")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let title = Expression<String>("title")
        let description = Expression<String?>("description")
        let url = Expression<String?>("url")
        let isDone = Expression<Bool>("is_done")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(title)
            t.column(description)
            t.column(url)
            t.column(isDone, defaultValue: false)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Ideas table created successfully")
    }
}
