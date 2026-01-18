import Foundation
import SQLite
import os

class Migration_20260118_TransportForWhom {

    private let migrationName = "20260118_TransportForWhom"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try addForWhomColumn(logger: logger)
            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func addForWhomColumn(logger: Logger) throws {
        let table = Table("transports")
        let forWhom = Expression<String?>("for_whom")

        // Add the for_whom column to the transports table
        try db.run(table.addColumn(forWhom, defaultValue: nil))

        logger.debug("Added for_whom column to transports table")
    }
}
