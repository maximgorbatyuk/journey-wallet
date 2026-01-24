import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct Checklist: Codable, Identifiable, Equatable, Hashable, Transferable {
    let id: UUID
    let journeyId: UUID
    var name: String
    var sortingOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        name: String,
        sortingOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.name = name
        self.sortingOrder = sortingOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .checklist)
    }
}

extension UTType {
    static var checklist: UTType {
        UTType(exportedAs: "dev.mgorbatyuk.journeywallet.checklist")
    }
}
