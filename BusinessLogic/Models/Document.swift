import Foundation

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case pdf
    case jpeg
    case png
    case heic
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        case .heic: return "HEIC"
        case .other: return L("document.type.other")
        }
    }

    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .jpeg, .png, .heic: return "photo.fill"
        case .other: return "doc.fill"
        }
    }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        case .other: return ""
        }
    }

    static func fromExtension(_ ext: String) -> DocumentType {
        switch ext.lowercased() {
        case "pdf": return .pdf
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "heic": return .heic
        default: return .other
        }
    }

    static func fromMimeType(_ mimeType: String) -> DocumentType {
        switch mimeType.lowercased() {
        case "application/pdf": return .pdf
        case "image/jpeg": return .jpeg
        case "image/png": return .png
        case "image/heic": return .heic
        default: return .other
        }
    }
}

struct Document: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var name: String
    var fileType: DocumentType
    var fileName: String
    var fileSize: Int64
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        name: String,
        fileType: DocumentType,
        fileName: String,
        fileSize: Int64,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.name = name
        self.fileType = fileType
        self.fileName = fileName
        self.fileSize = fileSize
        self.notes = notes
        self.createdAt = createdAt
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var isImage: Bool {
        switch fileType {
        case .jpeg, .png, .heic: return true
        default: return false
        }
    }

    var isPDF: Bool {
        fileType == .pdf
    }
}
