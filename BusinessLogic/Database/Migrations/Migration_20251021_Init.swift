import Foundation
import SQLite
import os

class Migration_20251021_Init {

    private let migrationName = "20251021_Init"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.awesomeapplication.migrations", category: migrationName)

        do {
            let tableName = "template_table"

            let table = Table(tableName)

            let id = Expression<Int64>("id")
            let name = Expression<String>("name")
            let createdAt = Expression<Date>("created_at")

            let createTableCommand = table.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(name)
                t.column(createdAt)
            }

            try db.run(createTableCommand)
            logger.debug("Template table created successfully")

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }
}
