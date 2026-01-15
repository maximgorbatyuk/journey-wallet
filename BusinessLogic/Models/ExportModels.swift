import Foundation

struct ExportData: Codable {
    let metadata: ExportMetadata
    let userSettings: ExportUserSettings
}

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

struct ExportUserSettings: Codable {
    let preferredCurrency: String
    let preferredLanguage: String

    init(currency: Currency, language: AppLanguage) {
        self.preferredCurrency = currency.rawValue
        self.preferredLanguage = language.rawValue
    }
}

// MARK: - Validation Errors

enum ExportValidationError: LocalizedError {
    case invalidJSON
    case missingMetadata
    case missingRequiredFields
    case incompatibleSchemaVersion(current: Int, file: Int)
    case newerSchemaVersion(current: Int, file: Int)
    case invalidDate
    case invalidNumericValue(field: String)
    case invalidCurrency(code: String)
    case invalidEnumValue(type: String, value: String)
    case invalidReference(type: String, id: Int64)
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return String(localized: "export.error.invalid_json")
        case .missingMetadata:
            return String(localized: "export.error.missing_metadata")
        case .missingRequiredFields:
            return String(localized: "export.error.missing_fields")
        case .incompatibleSchemaVersion(let current, let file):
            return String(localized: "export.error.incompatible_schema \(current) \(file)")
        case .newerSchemaVersion(let current, let file):
            return String(localized: "export.error.newer_schema \(current) \(file)")
        case .invalidDate:
            return String(localized: "export.error.invalid_date")
        case .invalidNumericValue(let field):
            return String(localized: "export.error.invalid_numeric \(field)")
        case .invalidCurrency(let code):
            return String(localized: "export.error.invalid_currency \(code)")
        case .invalidEnumValue(let type, let value):
            return String(localized: "export.error.invalid_enum \(type) \(value)")
        case .invalidReference(let type, let id):
            return String(localized: "export.error.invalid_reference \(type) \(id)")
        case .corruptedData:
            return String(localized: "export.error.corrupted")
        }
    }
}
