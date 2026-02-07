import Foundation

struct RoadmapStop: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var title: String
    var subtitle: String?
    var arrivalDate: Date?
    var departureDate: Date?
    var sortOrder: Int
    var outgoingTransportId: UUID?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        title: String,
        subtitle: String? = nil,
        arrivalDate: Date? = nil,
        departureDate: Date? = nil,
        sortOrder: Int = 0,
        outgoingTransportId: UUID? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.title = title
        self.subtitle = subtitle
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.sortOrder = sortOrder
        self.outgoingTransportId = outgoingTransportId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
