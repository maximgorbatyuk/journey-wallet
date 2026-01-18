import Foundation
import SQLite
import os

class CarRentalsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let companyColumn = Expression<String>("company")
    private let pickupLocationColumn = Expression<String>("pickup_location")
    private let dropoffLocationColumn = Expression<String>("dropoff_location")
    private let pickupDateColumn = Expression<Date>("pickup_date")
    private let dropoffDateColumn = Expression<Date>("dropoff_date")
    private let bookingReferenceColumn = Expression<String?>("booking_reference")
    private let carTypeColumn = Expression<String?>("car_type")
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
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "CarRentalsRepository")
    }

    func fetchAll() -> [CarRental] {
        var rentals: [CarRental] = []

        do {
            for row in try db.prepare(table.order(pickupDateColumn.asc)) {
                if let rental = mapRowToCarRental(row) {
                    rentals.append(rental)
                }
            }
        } catch {
            logger.error("Failed to fetch all car rentals: \(error)")
        }

        return rentals
    }

    func fetchByJourneyId(journeyId: UUID) -> [CarRental] {
        var rentals: [CarRental] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(pickupDateColumn.asc)
            for row in try db.prepare(query) {
                if let rental = mapRowToCarRental(row) {
                    rentals.append(rental)
                }
            }
        } catch {
            logger.error("Failed to fetch car rentals for journey \(journeyId): \(error)")
        }

        return rentals
    }

    func fetchById(id: UUID) -> CarRental? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToCarRental(row)
            }
        } catch {
            logger.error("Failed to fetch car rental by id \(id): \(error)")
        }
        return nil
    }

    func fetchUpcoming() -> [CarRental] {
        var rentals: [CarRental] = []
        let now = Date()

        do {
            let query = table.filter(pickupDateColumn > now).order(pickupDateColumn.asc)
            for row in try db.prepare(query) {
                if let rental = mapRowToCarRental(row) {
                    rentals.append(rental)
                }
            }
        } catch {
            logger.error("Failed to fetch upcoming car rentals: \(error)")
        }

        return rentals
    }

    func fetchActive() -> [CarRental] {
        var rentals: [CarRental] = []
        let now = Date()

        do {
            let query = table.filter(pickupDateColumn <= now && dropoffDateColumn >= now).order(pickupDateColumn.asc)
            for row in try db.prepare(query) {
                if let rental = mapRowToCarRental(row) {
                    rentals.append(rental)
                }
            }
        } catch {
            logger.error("Failed to fetch active car rentals: \(error)")
        }

        return rentals
    }

    func insert(_ rental: CarRental) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- rental.id.uuidString,
                journeyIdColumn <- rental.journeyId.uuidString,
                companyColumn <- rental.company,
                pickupLocationColumn <- rental.pickupLocation,
                dropoffLocationColumn <- rental.dropoffLocation,
                pickupDateColumn <- rental.pickupDate,
                dropoffDateColumn <- rental.dropoffDate,
                bookingReferenceColumn <- rental.bookingReference,
                carTypeColumn <- rental.carType,
                costColumn <- rental.cost?.description,
                currencyColumn <- rental.currency?.rawValue,
                notesColumn <- rental.notes,
                createdAtColumn <- rental.createdAt,
                updatedAtColumn <- rental.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted car rental: \(rental.id)")
            return true
        } catch {
            logger.error("Failed to insert car rental: \(error)")
            return false
        }
    }

    func update(_ rental: CarRental) -> Bool {
        let record = table.filter(idColumn == rental.id.uuidString)

        do {
            try db.run(record.update(
                companyColumn <- rental.company,
                pickupLocationColumn <- rental.pickupLocation,
                dropoffLocationColumn <- rental.dropoffLocation,
                pickupDateColumn <- rental.pickupDate,
                dropoffDateColumn <- rental.dropoffDate,
                bookingReferenceColumn <- rental.bookingReference,
                carTypeColumn <- rental.carType,
                costColumn <- rental.cost?.description,
                currencyColumn <- rental.currency?.rawValue,
                notesColumn <- rental.notes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated car rental: \(rental.id)")
            return true
        } catch {
            logger.error("Failed to update car rental: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted car rental: \(id)")
            return true
        } catch {
            logger.error("Failed to delete car rental: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted car rentals for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete car rentals for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all car rentals")
            return true
        } catch {
            logger.error("Failed to delete all car rentals: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count car rentals: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count car rentals for journey: \(error)")
            return 0
        }
    }

    private func mapRowToCarRental(_ row: Row) -> CarRental? {
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

        return CarRental(
            id: id,
            journeyId: journeyId,
            company: row[companyColumn],
            pickupLocation: row[pickupLocationColumn],
            dropoffLocation: row[dropoffLocationColumn],
            pickupDate: row[pickupDateColumn],
            dropoffDate: row[dropoffDateColumn],
            bookingReference: row[bookingReferenceColumn],
            carType: row[carTypeColumn],
            cost: cost,
            currency: currency,
            notes: row[notesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
