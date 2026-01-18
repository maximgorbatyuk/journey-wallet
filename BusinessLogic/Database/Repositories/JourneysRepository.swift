import Foundation
import SQLite
import os

class JourneysRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let nameColumn = Expression<String>("name")
    private let destinationColumn = Expression<String>("destination")
    private let startDateColumn = Expression<Date>("start_date")
    private let endDateColumn = Expression<Date>("end_date")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "JourneysRepository")
    }

    func fetchAll() -> [Journey] {
        var journeys: [Journey] = []

        do {
            for row in try db.prepare(table.order(startDateColumn.desc)) {
                if let journey = mapRowToJourney(row) {
                    journeys.append(journey)
                }
            }
        } catch {
            logger.error("Failed to fetch all journeys: \(error)")
        }

        return journeys
    }

    func fetchById(id: UUID) -> Journey? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToJourney(row)
            }
        } catch {
            logger.error("Failed to fetch journey by id \(id): \(error)")
        }
        return nil
    }

    func fetchUpcoming() -> [Journey] {
        var journeys: [Journey] = []
        let now = Date()

        do {
            let query = table.filter(startDateColumn > now).order(startDateColumn.asc)
            for row in try db.prepare(query) {
                if let journey = mapRowToJourney(row) {
                    journeys.append(journey)
                }
            }
        } catch {
            logger.error("Failed to fetch upcoming journeys: \(error)")
        }

        return journeys
    }

    func fetchActive() -> [Journey] {
        var journeys: [Journey] = []
        let now = Date()

        do {
            let query = table.filter(startDateColumn <= now && endDateColumn >= now).order(startDateColumn.asc)
            for row in try db.prepare(query) {
                if let journey = mapRowToJourney(row) {
                    journeys.append(journey)
                }
            }
        } catch {
            logger.error("Failed to fetch active journeys: \(error)")
        }

        return journeys
    }

    func fetchPast() -> [Journey] {
        var journeys: [Journey] = []
        let now = Date()

        do {
            let query = table.filter(endDateColumn < now).order(startDateColumn.desc)
            for row in try db.prepare(query) {
                if let journey = mapRowToJourney(row) {
                    journeys.append(journey)
                }
            }
        } catch {
            logger.error("Failed to fetch past journeys: \(error)")
        }

        return journeys
    }

    func insert(_ journey: Journey) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- journey.id.uuidString,
                nameColumn <- journey.name,
                destinationColumn <- journey.destination,
                startDateColumn <- journey.startDate,
                endDateColumn <- journey.endDate,
                notesColumn <- journey.notes,
                createdAtColumn <- journey.createdAt,
                updatedAtColumn <- journey.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted journey: \(journey.id)")
            return true
        } catch {
            logger.error("Failed to insert journey: \(error)")
            return false
        }
    }

    func update(_ journey: Journey) -> Bool {
        let record = table.filter(idColumn == journey.id.uuidString)

        do {
            try db.run(record.update(
                nameColumn <- journey.name,
                destinationColumn <- journey.destination,
                startDateColumn <- journey.startDate,
                endDateColumn <- journey.endDate,
                notesColumn <- journey.notes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated journey: \(journey.id)")
            return true
        } catch {
            logger.error("Failed to update journey: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted journey: \(id)")
            return true
        } catch {
            logger.error("Failed to delete journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all journeys")
            return true
        } catch {
            logger.error("Failed to delete all journeys: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count journeys: \(error)")
            return 0
        }
    }

    private func mapRowToJourney(_ row: Row) -> Journey? {
        guard let id = UUID(uuidString: row[idColumn]) else {
            return nil
        }

        return Journey(
            id: id,
            name: row[nameColumn],
            destination: row[destinationColumn],
            startDate: row[startDateColumn],
            endDate: row[endDateColumn],
            notes: row[notesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
