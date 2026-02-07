import Foundation

enum RoadmapEntityType: String, Codable, CaseIterable {
    case hotel
    case carRental
    case placeToVisit
    case idea
    case expense
    case transport
}

struct RoadmapStopAttachment: Codable, Identifiable, Equatable {
    let id: UUID
    let roadmapStopId: UUID
    let entityType: String
    let entityId: UUID
    let createdAt: Date

    init(
        id: UUID = UUID(),
        roadmapStopId: UUID,
        entityType: String,
        entityId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.roadmapStopId = roadmapStopId
        self.entityType = entityType
        self.entityId = entityId
        self.createdAt = createdAt
    }
}
