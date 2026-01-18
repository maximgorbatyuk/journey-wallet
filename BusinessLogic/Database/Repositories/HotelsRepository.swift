import Foundation
import SQLite
import os

class HotelsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let nameColumn = Expression<String>("name")
    private let addressColumn = Expression<String>("address")
    private let checkInDateColumn = Expression<Date>("check_in_date")
    private let checkOutDateColumn = Expression<Date>("check_out_date")
    private let bookingReferenceColumn = Expression<String?>("booking_reference")
    private let roomTypeColumn = Expression<String?>("room_type")
    private let costColumn = Expression<String?>("cost")
    private let currencyColumn = Expression<String?>("currency")
    private let contactPhoneColumn = Expression<String?>("contact_phone")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "HotelsRepository")
    }

    func fetchAll() -> [Hotel] {
        var hotels: [Hotel] = []

        do {
            for row in try db.prepare(table.order(checkInDateColumn.asc)) {
                if let hotel = mapRowToHotel(row) {
                    hotels.append(hotel)
                }
            }
        } catch {
            logger.error("Failed to fetch all hotels: \(error)")
        }

        return hotels
    }

    func fetchByJourneyId(journeyId: UUID) -> [Hotel] {
        var hotels: [Hotel] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(checkInDateColumn.asc)
            for row in try db.prepare(query) {
                if let hotel = mapRowToHotel(row) {
                    hotels.append(hotel)
                }
            }
        } catch {
            logger.error("Failed to fetch hotels for journey \(journeyId): \(error)")
        }

        return hotels
    }

    func fetchById(id: UUID) -> Hotel? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToHotel(row)
            }
        } catch {
            logger.error("Failed to fetch hotel by id \(id): \(error)")
        }
        return nil
    }

    func fetchUpcoming() -> [Hotel] {
        var hotels: [Hotel] = []
        let now = Date()

        do {
            let query = table.filter(checkInDateColumn > now).order(checkInDateColumn.asc)
            for row in try db.prepare(query) {
                if let hotel = mapRowToHotel(row) {
                    hotels.append(hotel)
                }
            }
        } catch {
            logger.error("Failed to fetch upcoming hotels: \(error)")
        }

        return hotels
    }

    func fetchActive() -> [Hotel] {
        var hotels: [Hotel] = []
        let now = Date()

        do {
            let query = table.filter(checkInDateColumn <= now && checkOutDateColumn >= now).order(checkInDateColumn.asc)
            for row in try db.prepare(query) {
                if let hotel = mapRowToHotel(row) {
                    hotels.append(hotel)
                }
            }
        } catch {
            logger.error("Failed to fetch active hotels: \(error)")
        }

        return hotels
    }

    func insert(_ hotel: Hotel) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- hotel.id.uuidString,
                journeyIdColumn <- hotel.journeyId.uuidString,
                nameColumn <- hotel.name,
                addressColumn <- hotel.address,
                checkInDateColumn <- hotel.checkInDate,
                checkOutDateColumn <- hotel.checkOutDate,
                bookingReferenceColumn <- hotel.bookingReference,
                roomTypeColumn <- hotel.roomType,
                costColumn <- hotel.cost?.description,
                currencyColumn <- hotel.currency?.rawValue,
                contactPhoneColumn <- hotel.contactPhone,
                notesColumn <- hotel.notes,
                createdAtColumn <- hotel.createdAt,
                updatedAtColumn <- hotel.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted hotel: \(hotel.id)")
            return true
        } catch {
            logger.error("Failed to insert hotel: \(error)")
            return false
        }
    }

    func update(_ hotel: Hotel) -> Bool {
        let record = table.filter(idColumn == hotel.id.uuidString)

        do {
            try db.run(record.update(
                nameColumn <- hotel.name,
                addressColumn <- hotel.address,
                checkInDateColumn <- hotel.checkInDate,
                checkOutDateColumn <- hotel.checkOutDate,
                bookingReferenceColumn <- hotel.bookingReference,
                roomTypeColumn <- hotel.roomType,
                costColumn <- hotel.cost?.description,
                currencyColumn <- hotel.currency?.rawValue,
                contactPhoneColumn <- hotel.contactPhone,
                notesColumn <- hotel.notes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated hotel: \(hotel.id)")
            return true
        } catch {
            logger.error("Failed to update hotel: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted hotel: \(id)")
            return true
        } catch {
            logger.error("Failed to delete hotel: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted hotels for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete hotels for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all hotels")
            return true
        } catch {
            logger.error("Failed to delete all hotels: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count hotels: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count hotels for journey: \(error)")
            return 0
        }
    }

    private func mapRowToHotel(_ row: Row) -> Hotel? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]) else {
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

        return Hotel(
            id: id,
            journeyId: journeyId,
            name: row[nameColumn],
            address: row[addressColumn],
            checkInDate: row[checkInDateColumn],
            checkOutDate: row[checkOutDateColumn],
            bookingReference: row[bookingReferenceColumn],
            roomType: row[roomTypeColumn],
            cost: cost,
            currency: currency,
            contactPhone: row[contactPhoneColumn],
            notes: row[notesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
