import Foundation

struct Transport: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var type: TransportType
    var carrier: String?
    var transportNumber: String?
    var departureLocation: String
    var arrivalLocation: String
    var departureDate: Date
    var arrivalDate: Date
    var bookingReference: String?
    var seatNumber: String?
    var platform: String?
    var cost: Decimal?
    var currency: Currency?
    var notes: String?
    var forWhom: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        type: TransportType,
        carrier: String? = nil,
        transportNumber: String? = nil,
        departureLocation: String,
        arrivalLocation: String,
        departureDate: Date,
        arrivalDate: Date,
        bookingReference: String? = nil,
        seatNumber: String? = nil,
        platform: String? = nil,
        cost: Decimal? = nil,
        currency: Currency? = nil,
        notes: String? = nil,
        forWhom: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.type = type
        self.carrier = carrier
        self.transportNumber = transportNumber
        self.departureLocation = departureLocation
        self.arrivalLocation = arrivalLocation
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
        self.bookingReference = bookingReference
        self.seatNumber = seatNumber
        self.platform = platform
        self.cost = cost
        self.currency = currency
        self.notes = notes
        self.forWhom = forWhom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var duration: TimeInterval {
        arrivalDate.timeIntervalSince(departureDate)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var isUpcoming: Bool {
        departureDate > Date()
    }

    var isInProgress: Bool {
        let now = Date()
        return departureDate <= now && arrivalDate >= now
    }

    var isPast: Bool {
        arrivalDate < Date()
    }

    var formattedCost: String? {
        guard let cost = cost, let currency = currency else { return nil }
        return "\(currency.rawValue)\(cost)"
    }

    var shareText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var text = L("transport.share.prefix") + " " + type.displayName
        text += "\n" + L("transport.detail.route")
        text += "\n" + departureLocation + " → " + arrivalLocation
        text += "\n" + L("transport.detail.departure") + ": " + dateFormatter.string(from: departureDate)
        text += "\n" + L("transport.detail.arrival") + ": " + dateFormatter.string(from: arrivalDate)
        if let carrier = carrier, !carrier.isEmpty {
            text += "\n" + type.carrierLabel + ": " + carrier
        }
        if let number = transportNumber, !number.isEmpty {
            text += "\n" + type.numberLabel + ": " + number
        }
        if let ref = bookingReference, !ref.isEmpty {
            text += "\n" + L("transport.detail.booking_reference") + ": " + ref
        }
        return text
    }
}
