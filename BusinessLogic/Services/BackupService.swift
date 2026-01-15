import Foundation
import os

@MainActor
final class BackupService: ObservableObject {
    static let shared = BackupService(
        databaseManager: DatabaseManager.shared)

    // MARK: - Constants

    private let maxSafetyBackups = 3
    private let maxiCloudBackups = 5
    private let maxBackupAgeInDays = 30

    // MARK: - File Paths

    private var safetyBackupDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath
            .appendingPathComponent("awesome_application", isDirectory: true)
            .appendingPathComponent("safety_backups", isDirectory: true)
    }

    private var iCloudBackupDirectory: URL? {
        guard isiCloudAvailable() else {
            logger.warning("iCloud not available - ubiquity identity token is nil")
            return nil
        }

        var bundleIdentifier = Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.awesomeapplication"
        if (bundleIdentifier.contains("Debug")) {
            bundleIdentifier = bundleIdentifier.replacingOccurrences(of: "Debug", with: "")
        }

        let containerIdentifier = "iCloud.\(bundleIdentifier)"

        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) ?? FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            logger.warning("Failed to get iCloud container URL for identifier: \(containerIdentifier)")
            return nil
        }

        return containerURL
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("awesome_application", isDirectory: true)
            .appendingPathComponent("backups", isDirectory: true)
    }

    // MARK: - Dependencies

    private let currentSchemaVersion: Int
    private let settingsRepository: UserSettingsRepository?
    private let databaseManager: DatabaseManager
    private let networkMonitor: NetworkMonitor
    private let logger: Logger

    init(
        databaseManager: DatabaseManager = DatabaseManager.shared,
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.databaseManager = databaseManager
        self.networkMonitor = networkMonitor
        self.currentSchemaVersion = self.databaseManager.getDatabaseSchemaVersion()
        self.settingsRepository = self.databaseManager.userSettingsRepository!
        self.logger = Logger(subsystem: "dev.mgorbatyuk.awesomeapplication.businesslogic", category: "BackupService")
    }

    // MARK: - Export

    func exportData() async throws -> URL {
        let exportData = try await createExportData()
        let fileURL = try await saveExportToTemporaryFile(exportData)
        return fileURL
    }

    private func createExportData() async throws -> ExportData {
        let settings = try await fetchUserSettings()

        let metadata = ExportMetadata(
            createdAt: Date(),
            appVersion: getAppVersion(),
            deviceName: getDeviceName(),
            databaseSchemaVersion: currentSchemaVersion
        )

        return ExportData(
            metadata: metadata
        )
    }

    private func saveExportToTemporaryFile(_ exportData: ExportData) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "awesome_application_export_\(timestamp).json"

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        try jsonData.write(to: fileURL)

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = fileURL
        try mutableURL.setResourceValues(resourceValues)

        return fileURL
    }

    // MARK: - Import

    func importData(from fileURL: URL) async throws {
        let exportData = try await parseExportFile(fileURL)

        try validateExportData(exportData)

        let safetyBackupURL = try await createSafetyBackup()

        do {
            wipeAllData()

            try await importExportData(exportData)

            cleanupOldSafetyBackups()
        } catch {
            self.logger.error("Import failed: \(error.localizedDescription). Restoring from safety backup.")
            try await restoreFromSafetyBackup(safetyBackupURL)
            throw error
        }
    }

    func parseExportFile(_ fileURL: URL) async throws -> ExportData {
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ExportData.self, from: data)
        } catch {
            self.logger.error("Failed to parse export file: \(error)")
            throw ExportValidationError.invalidJSON
        }
    }

    func validateExportData(_ exportData: ExportData) throws {
        let metadata = exportData.metadata

        if metadata.databaseSchemaVersion > currentSchemaVersion {
            throw ExportValidationError.newerSchemaVersion(
                current: currentSchemaVersion,
                file: metadata.databaseSchemaVersion
            )
        }
    }

    private func createSafetyBackup() async throws -> URL {
        try FileManager.default.createDirectory(
            at: safetyBackupDirectory,
            withIntermediateDirectories: true
        )

        let exportData = try await createExportData()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "safety_backup_before_import_\(timestamp).json"

        let fileURL = safetyBackupDirectory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: fileURL)

        self.logger.info("Safety backup created at: \(fileURL.path)")

        return fileURL
    }

    private func restoreFromSafetyBackup(_ backupURL: URL) async throws {
        self.logger.info("Restoring from safety backup: \(backupURL.path)")

        let exportData = try await parseExportFile(backupURL)
        wipeAllData()
        try await importExportData(exportData)

        self.logger.info("Successfully restored from safety backup")
    }

    private func cleanupOldSafetyBackups() {
        do {
            let fileManager = FileManager.default
            let backupFiles = try fileManager.contentsOfDirectory(
                at: safetyBackupDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            let sortedBackups = try backupFiles.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }

            let backupsToDelete = sortedBackups.dropFirst(maxSafetyBackups)
            for backup in backupsToDelete {
                try fileManager.removeItem(at: backup)
                self.logger.info("Deleted old safety backup: \(backup.lastPathComponent)")
            }
        } catch {
            self.logger.error("Failed to cleanup old safety backups: \(error)")
        }
    }

    private func wipeAllData() -> Void {
        databaseManager.deleteAllData()
        self.logger.info("All data wiped from database")
    }

    private func importExportData(_ exportData: ExportData) async throws {
        let settings = exportData.metadata

        if let currency = Currency.allCases.first(where: { $0.rawValue == settings.userSettings.preferredCurrency }) {
            _ = settingsRepository!.upsertCurrency(currency.rawValue)
        }

        if let language = AppLanguage.allCases.first(where: { $0.rawValue == settings.userSettings.preferredLanguage }) {
            _ = settingsRepository!.upsertLanguage(language.rawValue)
        }

        self.logger.info("Successfully imported user settings")
    }

    // MARK: - Helper Methods

    private func fetchUserSettings() async throws -> ExportUserSettings {
        let currency = settingsRepository!.fetchCurrency()
        let language = settingsRepository!.fetchLanguage()

        return ExportUserSettings(currency: currency, language: language)
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func getDeviceName() -> String {
        return ProcessInfo.processInfo.hostName
    }

    // MARK: - iCloud Backup

    func isiCloudAvailable() -> Bool {
        let token = FileManager.default.ubiquityIdentityToken
        return token != nil
    }

    func checkiCloudStatus() throws {
        guard isiCloudAvailable() else {
            throw BackupError.iCloudNotAvailable
        }

        guard iCloudBackupDirectory != nil else {
            throw BackupError.iCloudNotAvailable
        }

        guard networkMonitor.checkConnectivity() else {
            logger.warning("Network unavailable for iCloud operation")
            throw BackupError.networkUnavailable
        }
    }

    func createiCloudBackup() async throws -> BackupInfo {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let exportData = try await createExportData()

        try await createiCloudDirectoryIfNeeded()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let isDevelopment = EnvironmentService.shared.isDevelopmentMode()
        let filename = isDevelopment
            ? "awesome_application_backup_dev_\(timestamp).json"
            : "awesome_application_backup_\(timestamp).json"

        let fileURL = backupDirectory.appendingPathComponent(filename)

        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var didResume = false

            coordinator.coordinate(
                writingItemAt: fileURL,
                options: .replacing,
                error: &coordinatorError
            ) { url in
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    encoder.dateEncodingStrategy = .iso8601

                    let jsonData = try encoder.encode(exportData)
                    try jsonData.write(to: url)

                    self.logger.info("iCloud backup created: \(filename)")
                    if !didResume {
                        didResume = true
                        continuation.resume()
                    }
                } catch {
                    self.logger.error("Failed to write iCloud backup: \(error)")
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let error = coordinatorError, !didResume {
                didResume = true
                continuation.resume(throwing: error)
            }
        }

        try await cleanupOldiCloudBackups()

        let backupInfo = try getBackupInfo(from: fileURL)
        return backupInfo
    }

    func listiCloudBackups() async throws -> [BackupInfo] {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?
            var didResume = false

            coordinator.coordinate(
                readingItemAt: backupDirectory,
                options: [.withoutChanges],
                error: &coordinatorError
            ) { url in
                do {
                    let fileManager = FileManager.default

                    if !fileManager.fileExists(atPath: url.path) {
                        try fileManager.createDirectory(
                            at: url,
                            withIntermediateDirectories: true
                        )
                        if !didResume {
                            didResume = true
                            continuation.resume(returning: [])
                        }
                        return
                    }

                    let files = try fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                        options: [.skipsHiddenFiles]
                    )

                    let jsonFiles = files.filter { $0.pathExtension == "json" }

                    var backups: [BackupInfo] = []
                    for fileURL in jsonFiles {
                        if let info = try? self.getBackupInfo(from: fileURL) {
                            backups.append(info)
                        }
                    }

                    backups.sort { $0.createdAt > $1.createdAt }

                    if !didResume {
                        didResume = true
                        continuation.resume(returning: backups)
                    }
                } catch {
                    self.logger.error("Failed to list iCloud backups: \(error)")
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let error = coordinatorError, !didResume {
                didResume = true
                continuation.resume(throwing: error)
            }
        }
    }

    func restoreFromiCloudBackup(_ backupInfo: BackupInfo) async throws {
        try checkiCloudStatus()

        let safetyBackupURL = try await createSafetyBackup()

        do {
            let exportData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ExportData, Error>) in
                let coordinator = NSFileCoordinator()
                var coordinatorError: NSError?
                var didResume = false

                coordinator.coordinate(
                    readingItemAt: backupInfo.fileURL,
                    options: [.withoutChanges],
                    error: &coordinatorError
                ) { url in
                    do {
                        let data = try Data(contentsOf: url)

                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        let exportData = try decoder.decode(ExportData.self, from: data)
                        if !didResume {
                            didResume = true
                            continuation.resume(returning: exportData)
                        }
                    } catch {
                        self.logger.error("Failed to read iCloud backup: \(error)")
                        if !didResume {
                            didResume = true
                            continuation.resume(throwing: error)
                        }
                    }
                }

                if let error = coordinatorError, !didResume {
                    didResume = true
                    continuation.resume(throwing: error)
                }
            }

            try validateExportData(exportData)
            wipeAllData()
            try await importExportData(exportData)

            self.logger.info("Successfully restored from iCloud backup: \(backupInfo.fileName)")
        } catch {
            self.logger.error("Restore from iCloud failed: \(error.localizedDescription). Restoring from safety backup.")
            try await restoreFromSafetyBackup(safetyBackupURL)
            throw error
        }
    }

    func deleteiCloudBackup(_ backupInfo: BackupInfo) async throws {
        try checkiCloudStatus()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?
            var didResume = false

            coordinator.coordinate(
                writingItemAt: backupInfo.fileURL,
                options: .deleting,
                error: &coordinatorError
            ) { url in
                do {
                    try FileManager.default.removeItem(at: url)
                    self.logger.info("Deleted iCloud backup: \(backupInfo.fileName)")
                    if !didResume {
                        didResume = true
                        continuation.resume()
                    }
                } catch {
                    self.logger.error("Failed to delete iCloud backup: \(error)")
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let error = coordinatorError, !didResume {
                didResume = true
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteAlliCloudBackups() async throws {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let backups = try await listiCloudBackups()
        guard !backups.isEmpty else {
            return
        }

        for backup in backups {
            try await deleteiCloudBackup(backup)
        }

        self.logger.info("Deleted all iCloud backups: \(backups.count) files")
    }

    private func createiCloudDirectoryIfNeeded() async throws {
        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try fileManager.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
            self.logger.info("Created iCloud backup directory")
        }
    }

    private func cleanupOldiCloudBackups() async throws {
        guard let backupDirectory = iCloudBackupDirectory else {
            return
        }

        let backups = try await listiCloudBackups()

        let now = Date()
        let maxAge = TimeInterval(maxBackupAgeInDays * 24 * 60 * 60)

        var backupsToDelete: [BackupInfo] = []

        let oldBackups = backups.filter { now.timeIntervalSince($0.createdAt) > maxAge }
        backupsToDelete.append(contentsOf: oldBackups)

        if backups.count > maxiCloudBackups {
            let excessBackups = backups.dropFirst(maxiCloudBackups)
            backupsToDelete.append(contentsOf: excessBackups)
        }

        let uniqueBackupsToDelete = Array(Set(backupsToDelete.map { $0.fileURL }))

        for fileURL in uniqueBackupsToDelete {
            if let backup = backups.first(where: { $0.fileURL == fileURL }) {
                try? await deleteiCloudBackup(backup)
            }
        }

        if !uniqueBackupsToDelete.isEmpty {
            self.logger.info("Cleaned up \(uniqueBackupsToDelete.count) old iCloud backup(s)")
        }
    }

    private func getBackupInfo(from fileURL: URL) throws -> BackupInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)

        let creationDate = attributes[.creationDate] as? Date ?? Date()
        let fileSize = attributes[.size] as? Int64 ?? 0

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)

        return BackupInfo(
            fileName: fileURL.lastPathComponent,
            fileURL: fileURL,
            createdAt: creationDate,
            fileSize: fileSize,
            deviceName: exportData.metadata.deviceName,
            appVersion: exportData.metadata.appVersion,
            schemaVersion: exportData.metadata.databaseSchemaVersion,
            notificationsCount: 0
        )
    }

    // MARK: - Backup Models

    struct BackupInfo: Identifiable, Hashable {
        let fileName: String
        let fileURL: URL
        let createdAt: Date
        let fileSize: Int64
        let deviceName: String
        let appVersion: String
        let schemaVersion: Int
        let notificationsCount: Int

        var id: String { fileURL.absoluteString }
        var isDevBackup: Bool { fileName.contains("_dev_") }
        var formattedFileSize: String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: fileSize)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(fileURL)
        }
    }

    static func == (lhs: BackupInfo, rhs: BackupInfo) -> Bool {
        return lhs.fileURL == rhs.fileURL
    }
}

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case networkUnavailable
    case iCloudStorageFull
    case devBackupRestoreOnProdApp

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return String(localized: "backup.error.icloud_not_available")
        case .networkUnavailable:
            return String(localized: "backup.error.network_unavailable")
        case .iCloudStorageFull:
            return String(localized: "backup.error.icloud_storage_full")
        case .devBackupRestoreOnProdApp:
            return String(localized: "backup.error.dev_backup_restore_on_prod_app")
        }
    }
}
