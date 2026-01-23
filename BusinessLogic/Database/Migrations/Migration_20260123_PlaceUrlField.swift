import Foundation
import SQLite
import os

class Migration_20260123_PlaceUrlField {

    private let migrationName = "20260123_PlaceUrlField"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try addUrlColumn(logger: logger)
            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func addUrlColumn(logger: Logger) throws {
        let table = Table("places_to_visit")
        let url = Expression<String?>("url")

        // Add the url column to the places_to_visit table
        try db.run(table.addColumn(url, defaultValue: nil))

        logger.debug("Added url column to places_to_visit table")
    }
}
