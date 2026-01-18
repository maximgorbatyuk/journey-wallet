import Foundation

struct Journey: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var isUpcoming: Bool {
        startDate > Date()
    }

    var isActive: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }

    var isPast: Bool {
        endDate < Date()
    }
}
