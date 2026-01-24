import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct ChecklistItem: Codable, Identifiable, Equatable, Hashable, Transferable {
    let id: UUID
    let checklistId: UUID
    var name: String
    var isChecked: Bool
    var sortingOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        checklistId: UUID,
        name: String,
        isChecked: Bool = false,
        sortingOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.checklistId = checklistId
        self.name = name
        self.isChecked = isChecked
        self.sortingOrder = sortingOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var statusIcon: String {
        isChecked ? "checkmark.circle.fill" : "circle"
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .checklistItem)
    }
}

extension UTType {
    static var checklistItem: UTType {
        UTType(exportedAs: "dev.mgorbatyuk.journeywallet.checklistitem")
    }
}
