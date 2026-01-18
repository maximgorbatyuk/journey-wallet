import Foundation

struct CarRental: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var company: String
    var pickupLocation: String
    var dropoffLocation: String
    var pickupDate: Date
    var dropoffDate: Date
    var bookingReference: String?
    var carType: String?
    var cost: Decimal?
    var currency: Currency?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        company: String,
        pickupLocation: String,
        dropoffLocation: String,
        pickupDate: Date,
        dropoffDate: Date,
        bookingReference: String? = nil,
        carType: String? = nil,
        cost: Decimal? = nil,
        currency: Currency? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.company = company
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.pickupDate = pickupDate
        self.dropoffDate = dropoffDate
        self.bookingReference = bookingReference
        self.carType = carType
        self.cost = cost
        self.currency = currency
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var rentalDays: Int {
        Calendar.current.dateComponents([.day], from: pickupDate, to: dropoffDate).day ?? 0
    }

    var durationDays: Int { max(1, rentalDays) }

    var isUpcoming: Bool {
        pickupDate > Date()
    }

    var isActive: Bool {
        let now = Date()
        return pickupDate <= now && dropoffDate >= now
    }

    var isPast: Bool {
        dropoffDate < Date()
    }

    var formattedCost: String? {
        guard let cost = cost, let currency = currency else { return nil }
        return "\(currency.rawValue)\(cost)"
    }

    var costPerDay: Decimal? {
        guard let cost = cost, rentalDays > 0 else { return nil }
        return cost / Decimal(rentalDays)
    }

    var isSameLocation: Bool {
        pickupLocation == dropoffLocation
    }
}
