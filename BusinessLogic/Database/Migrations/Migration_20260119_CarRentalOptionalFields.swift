import Foundation
import SQLite
import os

class Migration_20260119_CarRentalOptionalFields {

    private let migrationName = "20260119_CarRentalOptionalFields"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try migrateCarRentalsTable(logger: logger)
            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func migrateCarRentalsTable(logger: Logger) throws {
        // SQLite doesn't support ALTER COLUMN directly, so we need to:
        // 1. Create a new table with the new schema
        // 2. Copy data from old table (handling NULL car_type)
        // 3. Drop old table
        // 4. Rename new table

        let tableName = "car_rentals"
        let tempTableName = "car_rentals_temp"

        // Step 1: Create temporary table with new schema
        try db.run("""
            CREATE TABLE \(tempTableName) (
                id TEXT PRIMARY KEY,
                journey_id TEXT NOT NULL,
                company TEXT,
                pickup_location TEXT,
                dropoff_location TEXT,
                pickup_date REAL NOT NULL,
                dropoff_date REAL NOT NULL,
                booking_reference TEXT,
                car_type TEXT NOT NULL DEFAULT '',
                cost TEXT,
                currency TEXT,
                notes TEXT,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            )
        """)

        logger.debug("Created temporary table with new schema")

        // Step 2: Copy data from old table, using empty string for NULL car_type
        try db.run("""
            INSERT INTO \(tempTableName) (id, journey_id, company, pickup_location, dropoff_location, pickup_date, dropoff_date, booking_reference, car_type, cost, currency, notes, created_at, updated_at)
            SELECT id, journey_id, company, pickup_location, dropoff_location, pickup_date, dropoff_date, booking_reference, COALESCE(car_type, ''), cost, currency, notes, created_at, updated_at
            FROM \(tableName)
        """)

        logger.debug("Copied data to temporary table")

        // Step 3: Drop old table
        try db.run("DROP TABLE \(tableName)")

        logger.debug("Dropped old table")

        // Step 4: Rename temporary table
        try db.run("ALTER TABLE \(tempTableName) RENAME TO \(tableName)")

        logger.debug("Renamed temporary table to \(tableName)")

        // Step 5: Recreate index
        try db.run("CREATE INDEX IF NOT EXISTS index_car_rentals_journey_id ON \(tableName) (journey_id)")

        logger.debug("Recreated journey_id index")
    }
}
