import Foundation

struct ExportMetadata: Codable {
    let createdAt: Date
    let appVersion: String
    let deviceName: String
    let databaseSchemaVersion: Int

    init(createdAt: Date = Date(),
         appVersion: String,
         deviceName: String,
         databaseSchemaVersion: Int) {
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.deviceName = deviceName
        self.databaseSchemaVersion = databaseSchemaVersion
    }
}
