import Foundation

struct Hotel: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var name: String
    var address: String
    var checkInDate: Date
    var checkOutDate: Date
    var bookingReference: String?
    var roomType: String?
    var cost: Decimal?
    var currency: Currency?
    var contactPhone: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        name: String,
        address: String,
        checkInDate: Date,
        checkOutDate: Date,
        bookingReference: String? = nil,
        roomType: String? = nil,
        cost: Decimal? = nil,
        currency: Currency? = nil,
        contactPhone: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.name = name
        self.address = address
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
        self.bookingReference = bookingReference
        self.roomType = roomType
        self.cost = cost
        self.currency = currency
        self.contactPhone = contactPhone
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var nightsCount: Int {
        Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0
    }

    var isUpcoming: Bool {
        checkInDate > Date()
    }

    var isActive: Bool {
        let now = Date()
        return checkInDate <= now && checkOutDate >= now
    }

    var isPast: Bool {
        checkOutDate < Date()
    }

    var formattedCost: String? {
        guard let cost = cost, let currency = currency else { return nil }
        return "\(currency.rawValue)\(cost)"
    }

    var costPerNight: Decimal? {
        guard let cost = cost, nightsCount > 0 else { return nil }
        return cost / Decimal(nightsCount)
    }
}
