import Foundation
import os

/// Handles one-time migration of database and documents from the app's private container
/// to the shared App Group container (required for Share Extension access).
class DatabaseMigrationHelper {
    private static let logger = Logger(subsystem: "DatabaseMigration", category: "Migration")
    private static let migrationCompletedKey = "AppGroupMigrationCompleted"

    /// Migrates database and documents from old app container to shared App Group container.
    /// This is a one-time migration that runs on first launch after the update.
    /// Safe to call multiple times - will skip if already migrated.
    static func migrateToAppGroupIfNeeded() {
        // Check if migration was already completed
        if UserDefaults.standard.bool(forKey: migrationCompletedKey) {
            logger.debug("App Group migration already completed, skipping")
            return
        }

        // Verify App Group is configured
        guard AppGroupContainer.isConfigured else {
            logger.error("App Group is not configured, cannot migrate")
            return
        }

        let fileManager = FileManager.default

        // Migrate database
        migrateDatabase(fileManager: fileManager)

        // Migrate documents folder
        migrateDocuments(fileManager: fileManager)

        // Mark migration as completed
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
        logger.info("App Group migration completed successfully")
    }

    private static func migrateDatabase(fileManager: FileManager) {
        guard let oldDatabasePath = AppGroupContainer.legacyDatabaseURL else {
            logger.info("Could not determine legacy database path")
            return
        }

        let newDatabasePath = AppGroupContainer.databaseURL

        // Check if old database exists
        guard fileManager.fileExists(atPath: oldDatabasePath.path) else {
            logger.info("No legacy database found at \(oldDatabasePath.path), skipping database migration")
            return
        }

        // Check if new database already exists (don't overwrite)
        guard !fileManager.fileExists(atPath: newDatabasePath.path) else {
            logger.info("Database already exists in App Group container, skipping migration")
            // Clean up old database since new one exists
            cleanupLegacyDatabase(fileManager: fileManager, oldPath: oldDatabasePath)
            return
        }

        // Perform migration
        do {
            // Copy main database file
            try fileManager.copyItem(at: oldDatabasePath, to: newDatabasePath)
            logger.info("Database copied to App Group container")

            // Also copy SQLite journal files if they exist (WAL mode)
            copyJournalFileIfExists(
                fileManager: fileManager,
                from: oldDatabasePath.deletingPathExtension().appendingPathExtension("sqlite3-wal"),
                to: newDatabasePath.deletingPathExtension().appendingPathExtension("sqlite3-wal")
            )
            copyJournalFileIfExists(
                fileManager: fileManager,
                from: oldDatabasePath.deletingPathExtension().appendingPathExtension("sqlite3-shm"),
                to: newDatabasePath.deletingPathExtension().appendingPathExtension("sqlite3-shm")
            )

            // Clean up old files after successful migration
            cleanupLegacyDatabase(fileManager: fileManager, oldPath: oldDatabasePath)

            logger.info("Database migration completed successfully")
        } catch {
            logger.error("Failed to migrate database: \(error.localizedDescription)")
        }
    }

    private static func copyJournalFileIfExists(fileManager: FileManager, from source: URL, to destination: URL) {
        if fileManager.fileExists(atPath: source.path) {
            do {
                try fileManager.copyItem(at: source, to: destination)
                logger.debug("Copied journal file: \(source.lastPathComponent)")
            } catch {
                logger.warning("Failed to copy journal file \(source.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    private static func cleanupLegacyDatabase(fileManager: FileManager, oldPath: URL) {
        // Remove old database and journal files
        let filesToRemove = [
            oldPath,
            oldPath.deletingPathExtension().appendingPathExtension("sqlite3-wal"),
            oldPath.deletingPathExtension().appendingPathExtension("sqlite3-shm")
        ]

        for file in filesToRemove {
            if fileManager.fileExists(atPath: file.path) {
                do {
                    try fileManager.removeItem(at: file)
                    logger.debug("Removed legacy file: \(file.lastPathComponent)")
                } catch {
                    logger.warning("Failed to remove legacy file \(file.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    private static func migrateDocuments(fileManager: FileManager) {
        guard let oldDocumentsPath = AppGroupContainer.legacyDocumentsURL else {
            logger.info("Could not determine legacy documents path")
            return
        }

        let newDocumentsPath = AppGroupContainer.documentsURL

        // Check if old documents folder exists
        guard fileManager.fileExists(atPath: oldDocumentsPath.path) else {
            logger.info("No legacy documents folder found, skipping documents migration")
            return
        }

        // Get list of files to migrate
        do {
            let contents = try fileManager.contentsOfDirectory(at: oldDocumentsPath, includingPropertiesForKeys: nil)

            if contents.isEmpty {
                logger.info("Legacy documents folder is empty, skipping migration")
                try? fileManager.removeItem(at: oldDocumentsPath)
                return
            }

            // Copy each file individually (to handle partial migrations gracefully)
            for sourceFile in contents {
                let destinationFile = newDocumentsPath.appendingPathComponent(sourceFile.lastPathComponent)

                // Skip if file already exists in destination
                if fileManager.fileExists(atPath: destinationFile.path) {
                    logger.debug("Document already exists in App Group: \(sourceFile.lastPathComponent)")
                    continue
                }

                do {
                    try fileManager.copyItem(at: sourceFile, to: destinationFile)
                    logger.debug("Migrated document: \(sourceFile.lastPathComponent)")
                } catch {
                    logger.warning("Failed to migrate document \(sourceFile.lastPathComponent): \(error.localizedDescription)")
                }
            }

            // Clean up old documents folder
            try? fileManager.removeItem(at: oldDocumentsPath)
            logger.info("Documents migration completed, migrated \(contents.count) files")

        } catch {
            logger.error("Failed to read legacy documents folder: \(error.localizedDescription)")
        }
    }

    /// Resets the migration flag (for testing purposes only)
    static func resetMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: migrationCompletedKey)
        logger.warning("Migration flag reset - migration will run again on next launch")
    }
}
