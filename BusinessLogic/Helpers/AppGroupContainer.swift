import Foundation
import os

/// Helper for accessing the shared App Group container.
/// The App Group identifier is read from Info.plist (configured via xcconfig files).
enum AppGroupContainer {
    private static let logger = Logger(subsystem: "AppGroupContainer", category: "Storage")

    /// App Group identifier - read from Info.plist (configured via xcconfig)
    static var identifier: String {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            logger.error("AppGroupIdentifier not found in Info.plist")
            fatalError("AppGroupIdentifier not found in Info.plist. Check xcconfig setup.")
        }
        return identifier
    }

    /// Shared container URL for the App Group
    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            logger.error("App Group '\(identifier)' not configured. Check entitlements.")
            fatalError("App Group '\(identifier)' not configured")
        }
        return url
    }

    /// Database file URL in shared container
    static var databaseURL: URL {
        containerURL.appendingPathComponent("journey_wallet.sqlite3")
    }

    /// Documents directory in shared container
    static var documentsURL: URL {
        let url = containerURL.appendingPathComponent("JourneyDocuments")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Check if App Group is properly configured
    static var isConfigured: Bool {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            return false
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }

    /// Old database path (app's private Documents directory) - used for migration
    static var legacyDatabaseURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("journey_wallet.sqlite3")
    }

    /// Old documents path (app's private Documents directory) - used for migration
    static var legacyDocumentsURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("JourneyDocuments")
    }
}
