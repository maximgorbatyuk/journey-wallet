import Foundation
import SQLite
import os

protocol DatabaseManagerProtocol {
    func getDelayedNotificationsRepository() -> DelayedNotificationsRepository
}

class DatabaseManager : DatabaseManagerProtocol {

    static let MigrationsTableName = "migrations"
    static let UserSettingsTableName = "user_settings"
    static let DelayedNotificationsTableName = "delayed_notifications"
    static let JourneysTableName = "journeys"
    static let TransportsTableName = "transports"
    static let HotelsTableName = "hotels"
    static let CarRentalsTableName = "car_rentals"
    static let DocumentsTableName = "documents"
    static let NotesTableName = "notes"
    static let PlacesToVisitTableName = "places_to_visit"
    static let RemindersTableName = "reminders"
    static let ExpensesTableName = "expenses"

    static let shared = DatabaseManager()

    var migrationRepository: MigrationsRepository?
    var userSettingsRepository: UserSettingsRepository?
    var delayedNotificationsRepository: DelayedNotificationsRepository?

    private var db: Connection?
    private let logger: Logger
    private let latestVersion = 2

    private init() {

        self.logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.database", category: "DatabaseManager")

        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!

            let dbPath = "\(path)/journey_wallet.sqlite3"
            logger.debug("Database path: \(dbPath)")

            self.db = try Connection(dbPath)
            guard let dbConnection = db else {
                return
            }

            self.migrationRepository = MigrationsRepository(db: dbConnection, tableName: DatabaseManager.MigrationsTableName)
            self.userSettingsRepository = UserSettingsRepository(db: dbConnection, tableName: DatabaseManager.UserSettingsTableName)
            self.delayedNotificationsRepository = DelayedNotificationsRepository(db: dbConnection, tableName: DatabaseManager.DelayedNotificationsTableName)

            // Ensure user settings table exists
            self.userSettingsRepository?.createTable()

            migrateIfNeeded()
        } catch {
            logger.error("Unable to setup database: \(error)")
        }
    }

    func deleteAllData() -> Void {
        // to be implemented
    }

    func getDatabaseSchemaVersion() -> Int {
        return latestVersion;
    }

    func getDelayedNotificationsRepository() -> DelayedNotificationsRepository {
        return delayedNotificationsRepository!
    }

    func migrateIfNeeded() {

        guard let _ = db else { return }

        migrationRepository!.createTableIfNotExists()
        let currentVersion = migrationRepository!.getLatestMigrationVersion()

        if (currentVersion == latestVersion) {
            return
        }

        for version in (Int(currentVersion) + 1)...latestVersion {
            switch version {
            case 1:
                userSettingsRepository!.createTable()
                _ = userSettingsRepository!.upsertCurrency(Currency.kzt.rawValue)

            case 2:
                Migration_20260118_JourneyTables(db: db!).execute()

            default:
                break
            }

            migrationRepository!.addMigrationVersion()
        }

        func deleteAllData() -> Void {
            delayedNotificationsRepository!.truncateTable()
        }
    }
}
