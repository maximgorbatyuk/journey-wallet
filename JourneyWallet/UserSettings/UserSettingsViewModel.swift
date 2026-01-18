import Foundation
import UIKit
import os

@MainActor
class UserSettingsViewModel: ObservableObject {

    static let onboardingCompletedKey = "isOnboardingComplete"

    @Published var defaultCurrency: Currency
    @Published var selectedLanguage: AppLanguage
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportError: String?
    @Published var importError: String?
    @Published var showImportConfirmation: Bool = false
    @Published var pendingImportURL: URL?
    @Published var importPreviewData: ImportPreviewData?

    // iCloud Backup
    @Published var isBackingUp: Bool = false
    @Published var backupError: String?
    @Published var lastBackupDate: Date?
    @Published var iCloudBackups: [BackupInfo] = []
    @Published var isLoadingBackups: Bool = false
    @Published var showBackupList: Bool = false

    // Automatic Backup
    @Published var isAutomaticBackupEnabled: Bool = false
    @Published var lastAutomaticBackupDate: Date?

    private let environment: EnvironmentService
    private let backupService: BackupService
    private let backgroundTaskManager: BackgroundTaskManager
    private let db: DatabaseManager
    private let userSettingsRepository: UserSettingsRepository?
    private let developerMode: DeveloperModeManager

    private let logger: Logger

    init(
        environment: EnvironmentService = .shared,
        db: DatabaseManager = .shared,
        logger: Logger? = nil,
        developerMode: DeveloperModeManager = .shared,
        backupService: BackupService = .shared,
        backgroundTaskManager: BackgroundTaskManager = .shared
    ) {
        self.environment = environment
        self.db = db
        self.logger = logger ?? Logger(subsystem: "UserSettingsViewModel", category: "Views")
        self.developerMode = developerMode
        self.backupService = backupService
        self.backgroundTaskManager = backgroundTaskManager
        self.userSettingsRepository = db.userSettingsRepository

        self.defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .kzt
        self.selectedLanguage = userSettingsRepository?.fetchLanguage() ?? .en

        // Sync automatic backup state from BackgroundTaskManager
        self.isAutomaticBackupEnabled = backgroundTaskManager.isAutomaticBackupEnabled
        self.lastAutomaticBackupDate = backgroundTaskManager.lastAutomaticBackupDate
    }

    func handleVersionTap() -> Void {
        self.developerMode.handleVersionTap()
    }

    func openAppStoreForUpdate() -> Void {
        let urlAddress = environment.getAppStoreAppLink()
        if let url = URL(string: urlAddress) {
            self.openWebURL(url)
        }
    }

    func openWebURL(_ url: URL) {
        UIApplication.shared.open(url)
    }

    func getDefaultCurrency() -> Currency {
        return defaultCurrency
    }

    func saveDefaultCurrency(_ currency: Currency) -> Void {
        // update in-memory value first so UI updates
        DispatchQueue.main.async {
            self.defaultCurrency = currency
        }

        // persist to DB (upsert)
        let success = userSettingsRepository?.upsertCurrency(currency.rawValue) ?? false
        if !success {
            logger.error("Failed to save default currency \(currency.rawValue) to DB")
        }
    }

    // New: save selected language
    func saveLanguage(_ language: AppLanguage) -> Void {
        DispatchQueue.main.async {
            self.selectedLanguage = language
        }

        // Update runtime localization manager so UI can react immediately
        do {
            try LocalizationManager.shared.setLanguage(language)
        }
        catch {
            logger.error("Failed to set language to \(language.rawValue): \(error.localizedDescription)")
        }
        
    }

    func isSpecialDeveloperModeEnabled() -> Bool {
        return developerMode.isDeveloperModeEnabled
    }

    func isDevelopmentMode() -> Bool {
        return environment.isDevelopmentMode() ||
                developerMode.isDeveloperModeEnabled
    }

    func deleteAllData() -> Void {
        if (!isDevelopmentMode()) {
            self.logger.info("Attempt to delete all data in non-development mode. Operation aborted.")
            return
        }

        db.deleteAllData()
    }

    func addRandomExpenses() throws -> Void {
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }

    // MARK: - Export/Import

    func exportData() async -> URL? {
        isExporting = true
        exportError = nil

        do {
            let fileURL = try await backupService.exportData()
            isExporting = false
            logger.info("Export successful: \(fileURL.path)")
            return fileURL
        } catch {
            isExporting = false
            exportError = error.localizedDescription
            logger.error("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    func prepareImport(from fileURL: URL) async {
        isImporting = true
        importError = nil

        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let exportData = try await backupService.parseExportFile(fileURL)

            // Validate data
            try backupService.validateExportData(exportData)

            // Create preview data
            let preview = ImportPreviewData(
                deviceName: exportData.metadata.deviceName,
                exportDate: exportData.metadata.createdAt,
                appVersion: exportData.metadata.appVersion,
                schemaVersion: exportData.metadata.databaseSchemaVersion,
            )

            isImporting = false
            importPreviewData = preview
            pendingImportURL = fileURL
            showImportConfirmation = true
        } catch {
            isImporting = false
            importError = error.localizedDescription
            logger.error("Import preparation failed: \(error.localizedDescription)")
        }
    }

    func confirmImport() async {
        guard let fileURL = pendingImportURL else {
            logger.error("No pending import URL")
            return
        }

        isImporting = true
        importError = nil
        showImportConfirmation = false

        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try await backupService.importData(from: fileURL)

            isImporting = false
            pendingImportURL = nil
            importPreviewData = nil

            logger.info("Import successful")
        } catch {
            isImporting = false
            importError = error.localizedDescription
            logger.error("Import failed: \(error.localizedDescription)")
        }
    }

    func cancelImport() {
        pendingImportURL = nil
        importPreviewData = nil
        showImportConfirmation = false
    }

    // MARK: - iCloud Backup

    func createiCloudBackup() async {
        guard backupService.isiCloudAvailable() else {
            backupError = String(localized: "backup.error.icloud_not_available")
            return
        }

        isBackingUp = true
        backupError = nil

        do {
            let backupInfo = try await backupService.createiCloudBackup()
            isBackingUp = false
            lastBackupDate = backupInfo.createdAt
            logger.info("iCloud backup created successfully")
        } catch {
            isBackingUp = false
            backupError = error.localizedDescription
            logger.error("iCloud backup failed: \(error.localizedDescription)")
        }
    }

    func loadiCloudBackups() async {
        guard backupService.isiCloudAvailable() else {
            backupError = String(localized: "backup.error.icloud_not_available")
            return
        }

        isLoadingBackups = true
        backupError = nil

        do {
            let backups = try await backupService.listiCloudBackups()
            isLoadingBackups = false
            iCloudBackups = backups

            // Update last backup date
            if let latest = backups.first {
                lastBackupDate = latest.createdAt
            }
        } catch {
            isLoadingBackups = false
            backupError = error.localizedDescription
            logger.error("Failed to load iCloud backups: \(error.localizedDescription)")
        }
    }

    func restoreFromiCloudBackup(_ backupInfo: BackupInfo) async {
        isImporting = true
        importError = nil

        do {
            if backupInfo.isDevBackup && !environment.isDevelopmentMode() {
                throw BackupError.devBackupRestoreOnProdApp
            }

            try await backupService.restoreFromiCloudBackup(backupInfo)
            isImporting = false
            logger.info("Restored from iCloud backup successfully")
        } catch {
            isImporting = false
            importError = error.localizedDescription
            logger.error("Failed to restore from iCloud backup: \(error.localizedDescription)")
        }
    }

    func deleteiCloudBackup(_ backupInfo: BackupInfo) async {
        do {
            try await backupService.deleteiCloudBackup(backupInfo)

            // Reload backups
            await loadiCloudBackups()
            logger.info("Deleted iCloud backup successfully")
        } catch {
            backupError = error.localizedDescription
            logger.error("Failed to delete iCloud backup: \(error.localizedDescription)")
        }
    }

    func deleteAlliCloudBackups() async {
        do {
            try await backupService.deleteAlliCloudBackups()

            // Reload backups
            await loadiCloudBackups()
            logger.info("Deleted all iCloud backups successfully")
        } catch {
            backupError = error.localizedDescription
            logger.error("Failed to delete all iCloud backups: \(error.localizedDescription)")
        }
    }

    func isiCloudAvailable() -> Bool {
        return backupService.isiCloudAvailable()
    }

    // MARK: - Automatic Backup

    func toggleAutomaticBackup(_ enabled: Bool) {
        isAutomaticBackupEnabled = enabled
        backgroundTaskManager.isAutomaticBackupEnabled = enabled
        logger.info("Automatic backup \(enabled ? "enabled" : "disabled")")
    }

    func refreshAutomaticBackupState() {
        isAutomaticBackupEnabled = backgroundTaskManager.isAutomaticBackupEnabled
        lastAutomaticBackupDate = backgroundTaskManager.lastAutomaticBackupDate
    }

    // MARK: - Random Data Generation (Developer Only)

    func generateRandomDataForJourney(_ journey: Journey) {
        guard isDevelopmentMode() else {
            logger.warning("Attempt to generate random data in non-development mode. Operation aborted.")
            return
        }

        logger.info("Generating random data for journey: \(journey.name) (ID: \(journey.id))")

        let generator = RandomDataGenerator(db: db)
        generator.generateRandomData(for: journey)

        logger.info("Random data generation completed for journey: \(journey.name)")
    }
}

// MARK: - Import Preview Data

struct ImportPreviewData {
    let deviceName: String
    let exportDate: Date
    let appVersion: String
    let schemaVersion: Int
}
