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
    var journeysRepository: JourneysRepository?
    var transportsRepository: TransportsRepository?
    var hotelsRepository: HotelsRepository?
    var carRentalsRepository: CarRentalsRepository?
    var documentsRepository: DocumentsRepository?
    var notesRepository: NotesRepository?
    var placesToVisitRepository: PlacesToVisitRepository?
    var remindersRepository: RemindersRepository?
    var expensesRepository: ExpensesRepository?

    private var db: Connection?
    private let logger: Logger
    private let latestVersion = 6

    private init() {

        self.logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.database", category: "DatabaseManager")

        // IMPORTANT: Migrate database BEFORE opening connection.
        // This must happen here because DatabaseManager.shared may be accessed
        // before UIApplicationDelegate.didFinishLaunchingWithOptions (e.g., by ColorSchemeManager)
        DatabaseMigrationHelper.migrateToAppGroupIfNeeded()

        do {
            // Use App Group shared container for database (enables Share Extension access)
            let dbURL = AppGroupContainer.databaseURL
            let dbPath = dbURL.path
            logger.debug("Database path: \(dbPath)")

            self.db = try Connection(dbPath)
            guard let dbConnection = db else {
                return
            }

            self.migrationRepository = MigrationsRepository(db: dbConnection, tableName: DatabaseManager.MigrationsTableName)
            self.userSettingsRepository = UserSettingsRepository(db: dbConnection, tableName: DatabaseManager.UserSettingsTableName)
            self.delayedNotificationsRepository = DelayedNotificationsRepository(db: dbConnection, tableName: DatabaseManager.DelayedNotificationsTableName)
            self.journeysRepository = JourneysRepository(db: dbConnection, tableName: DatabaseManager.JourneysTableName)
            self.transportsRepository = TransportsRepository(db: dbConnection, tableName: DatabaseManager.TransportsTableName)
            self.hotelsRepository = HotelsRepository(db: dbConnection, tableName: DatabaseManager.HotelsTableName)
            self.carRentalsRepository = CarRentalsRepository(db: dbConnection, tableName: DatabaseManager.CarRentalsTableName)
            self.documentsRepository = DocumentsRepository(db: dbConnection, tableName: DatabaseManager.DocumentsTableName)
            self.notesRepository = NotesRepository(db: dbConnection, tableName: DatabaseManager.NotesTableName)
            self.placesToVisitRepository = PlacesToVisitRepository(db: dbConnection, tableName: DatabaseManager.PlacesToVisitTableName)
            self.remindersRepository = RemindersRepository(db: dbConnection, tableName: DatabaseManager.RemindersTableName)
            self.expensesRepository = ExpensesRepository(db: dbConnection, tableName: DatabaseManager.ExpensesTableName)

            // Ensure user settings table exists
            self.userSettingsRepository?.createTable()

            migrateIfNeeded()
        } catch {
            logger.error("Unable to setup database: \(error)")
        }
    }

    func deleteAllData() {
        _ = expensesRepository?.deleteAll()
        _ = remindersRepository?.deleteAll()
        _ = placesToVisitRepository?.deleteAll()
        _ = notesRepository?.deleteAll()
        _ = documentsRepository?.deleteAll()
        _ = carRentalsRepository?.deleteAll()
        _ = hotelsRepository?.deleteAll()
        _ = transportsRepository?.deleteAll()
        _ = journeysRepository?.deleteAll()
        delayedNotificationsRepository?.truncateTable()
        logger.info("All data deleted from database")
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

            case 3:
                Migration_20260118_TransportForWhom(db: db!).execute()

            case 4:
                Migration_20260119_DocumentFilePath(db: db!).execute()

            case 5:
                Migration_20260119_CarRentalOptionalFields(db: db!).execute()

            case 6:
                Migration_20260123_PlaceUrlField(db: db!).execute()

            default:
                break
            }

            migrationRepository!.addMigrationVersion()
        }
    }
}
