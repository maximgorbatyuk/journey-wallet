import Foundation
import SQLite
import os

class Migration_20260119_DocumentFilePath {

    private let migrationName = "20260119_DocumentFilePath"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try addFilePathColumn(logger: logger)
            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func addFilePathColumn(logger: Logger) throws {
        let table = Table("documents")
        let filePath = Expression<String?>("file_path")

        // Add the file_path column to the documents table
        try db.run(table.addColumn(filePath, defaultValue: nil))

        logger.debug("Added file_path column to documents table")
    }
}
