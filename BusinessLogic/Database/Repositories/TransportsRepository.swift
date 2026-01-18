import Foundation
import SQLite
import os

class TransportsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let typeColumn = Expression<String>("type")
    private let carrierColumn = Expression<String?>("carrier")
    private let transportNumberColumn = Expression<String?>("transport_number")
    private let departureLocationColumn = Expression<String>("departure_location")
    private let arrivalLocationColumn = Expression<String>("arrival_location")
    private let departureDateColumn = Expression<Date>("departure_date")
    private let arrivalDateColumn = Expression<Date>("arrival_date")
    private let bookingReferenceColumn = Expression<String?>("booking_reference")
    private let seatNumberColumn = Expression<String?>("seat_number")
    private let platformColumn = Expression<String?>("platform")
    private let costColumn = Expression<String?>("cost")
    private let currencyColumn = Expression<String?>("currency")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "TransportsRepository")
    }

    func fetchAll() -> [Transport] {
        var transports: [Transport] = []

        do {
            for row in try db.prepare(table.order(departureDateColumn.asc)) {
                if let transport = mapRowToTransport(row) {
                    transports.append(transport)
                }
            }
        } catch {
            logger.error("Failed to fetch all transports: \(error)")
        }

        return transports
    }

    func fetchByJourneyId(journeyId: UUID) -> [Transport] {
        var transports: [Transport] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(departureDateColumn.asc)
            for row in try db.prepare(query) {
                if let transport = mapRowToTransport(row) {
                    transports.append(transport)
                }
            }
        } catch {
            logger.error("Failed to fetch transports for journey \(journeyId): \(error)")
        }

        return transports
    }

    func fetchById(id: UUID) -> Transport? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToTransport(row)
            }
        } catch {
            logger.error("Failed to fetch transport by id \(id): \(error)")
        }
        return nil
    }

    func fetchUpcoming() -> [Transport] {
        var transports: [Transport] = []
        let now = Date()

        do {
            let query = table.filter(departureDateColumn > now).order(departureDateColumn.asc)
            for row in try db.prepare(query) {
                if let transport = mapRowToTransport(row) {
                    transports.append(transport)
                }
            }
        } catch {
            logger.error("Failed to fetch upcoming transports: \(error)")
        }

        return transports
    }

    func fetchByType(type: TransportType) -> [Transport] {
        var transports: [Transport] = []

        do {
            let query = table.filter(typeColumn == type.rawValue).order(departureDateColumn.asc)
            for row in try db.prepare(query) {
                if let transport = mapRowToTransport(row) {
                    transports.append(transport)
                }
            }
        } catch {
            logger.error("Failed to fetch transports by type \(type.rawValue): \(error)")
        }

        return transports
    }

    func insert(_ transport: Transport) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- transport.id.uuidString,
                journeyIdColumn <- transport.journeyId.uuidString,
                typeColumn <- transport.type.rawValue,
                carrierColumn <- transport.carrier,
                transportNumberColumn <- transport.transportNumber,
                departureLocationColumn <- transport.departureLocation,
                arrivalLocationColumn <- transport.arrivalLocation,
                departureDateColumn <- transport.departureDate,
                arrivalDateColumn <- transport.arrivalDate,
                bookingReferenceColumn <- transport.bookingReference,
                seatNumberColumn <- transport.seatNumber,
                platformColumn <- transport.platform,
                costColumn <- transport.cost?.description,
                currencyColumn <- transport.currency?.rawValue,
                notesColumn <- transport.notes,
                createdAtColumn <- transport.createdAt,
                updatedAtColumn <- transport.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted transport: \(transport.id)")
            return true
        } catch {
            logger.error("Failed to insert transport: \(error)")
            return false
        }
    }

    func update(_ transport: Transport) -> Bool {
        let record = table.filter(idColumn == transport.id.uuidString)

        do {
            try db.run(record.update(
                typeColumn <- transport.type.rawValue,
                carrierColumn <- transport.carrier,
                transportNumberColumn <- transport.transportNumber,
                departureLocationColumn <- transport.departureLocation,
                arrivalLocationColumn <- transport.arrivalLocation,
                departureDateColumn <- transport.departureDate,
                arrivalDateColumn <- transport.arrivalDate,
                bookingReferenceColumn <- transport.bookingReference,
                seatNumberColumn <- transport.seatNumber,
                platformColumn <- transport.platform,
                costColumn <- transport.cost?.description,
                currencyColumn <- transport.currency?.rawValue,
                notesColumn <- transport.notes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated transport: \(transport.id)")
            return true
        } catch {
            logger.error("Failed to update transport: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted transport: \(id)")
            return true
        } catch {
            logger.error("Failed to delete transport: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted transports for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete transports for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all transports")
            return true
        } catch {
            logger.error("Failed to delete all transports: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count transports: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count transports for journey: \(error)")
            return 0
        }
    }

    private func mapRowToTransport(_ row: Row) -> Transport? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]),
              let type = TransportType(rawValue: row[typeColumn]) else {
            return nil
        }

        var cost: Decimal?
        if let costString = row[costColumn] {
            cost = Decimal(string: costString)
        }

        var currency: Currency?
        if let currencyString = row[currencyColumn] {
            currency = Currency(rawValue: currencyString)
        }

        return Transport(
            id: id,
            journeyId: journeyId,
            type: type,
            carrier: row[carrierColumn],
            transportNumber: row[transportNumberColumn],
            departureLocation: row[departureLocationColumn],
            arrivalLocation: row[arrivalLocationColumn],
            departureDate: row[departureDateColumn],
            arrivalDate: row[arrivalDateColumn],
            bookingReference: row[bookingReferenceColumn],
            seatNumber: row[seatNumberColumn],
            platform: row[platformColumn],
            cost: cost,
            currency: currency,
            notes: row[notesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
