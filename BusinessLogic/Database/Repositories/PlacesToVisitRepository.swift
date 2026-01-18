import Foundation
import SQLite
import os

class PlacesToVisitRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let nameColumn = Expression<String>("name")
    private let addressColumn = Expression<String?>("address")
    private let categoryColumn = Expression<String>("category")
    private let isVisitedColumn = Expression<Bool>("is_visited")
    private let plannedDateColumn = Expression<Date?>("planned_date")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "PlacesToVisitRepository")
    }

    func fetchAll() -> [PlaceToVisit] {
        var places: [PlaceToVisit] = []

        do {
            for row in try db.prepare(table.order(plannedDateColumn.asc, nameColumn.asc)) {
                if let place = mapRowToPlace(row) {
                    places.append(place)
                }
            }
        } catch {
            logger.error("Failed to fetch all places: \(error)")
        }

        return places
    }

    func fetchByJourneyId(journeyId: UUID) -> [PlaceToVisit] {
        var places: [PlaceToVisit] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(plannedDateColumn.asc, nameColumn.asc)
            for row in try db.prepare(query) {
                if let place = mapRowToPlace(row) {
                    places.append(place)
                }
            }
        } catch {
            logger.error("Failed to fetch places for journey \(journeyId): \(error)")
        }

        return places
    }

    func fetchById(id: UUID) -> PlaceToVisit? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToPlace(row)
            }
        } catch {
            logger.error("Failed to fetch place by id \(id): \(error)")
        }
        return nil
    }

    func fetchByCategory(category: PlaceCategory) -> [PlaceToVisit] {
        var places: [PlaceToVisit] = []

        do {
            let query = table.filter(categoryColumn == category.rawValue).order(plannedDateColumn.asc)
            for row in try db.prepare(query) {
                if let place = mapRowToPlace(row) {
                    places.append(place)
                }
            }
        } catch {
            logger.error("Failed to fetch places by category \(category.rawValue): \(error)")
        }

        return places
    }

    func fetchUnvisited(journeyId: UUID) -> [PlaceToVisit] {
        var places: [PlaceToVisit] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString && isVisitedColumn == false)
                .order(plannedDateColumn.asc, nameColumn.asc)
            for row in try db.prepare(query) {
                if let place = mapRowToPlace(row) {
                    places.append(place)
                }
            }
        } catch {
            logger.error("Failed to fetch unvisited places: \(error)")
        }

        return places
    }

    func fetchVisited(journeyId: UUID) -> [PlaceToVisit] {
        var places: [PlaceToVisit] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString && isVisitedColumn == true)
                .order(plannedDateColumn.asc, nameColumn.asc)
            for row in try db.prepare(query) {
                if let place = mapRowToPlace(row) {
                    places.append(place)
                }
            }
        } catch {
            logger.error("Failed to fetch visited places: \(error)")
        }

        return places
    }

    func insert(_ place: PlaceToVisit) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- place.id.uuidString,
                journeyIdColumn <- place.journeyId.uuidString,
                nameColumn <- place.name,
                addressColumn <- place.address,
                categoryColumn <- place.category.rawValue,
                isVisitedColumn <- place.isVisited,
                plannedDateColumn <- place.plannedDate,
                notesColumn <- place.notes,
                createdAtColumn <- place.createdAt
            )
            try db.run(insert)
            logger.info("Inserted place: \(place.id)")
            return true
        } catch {
            logger.error("Failed to insert place: \(error)")
            return false
        }
    }

    func update(_ place: PlaceToVisit) -> Bool {
        let record = table.filter(idColumn == place.id.uuidString)

        do {
            try db.run(record.update(
                nameColumn <- place.name,
                addressColumn <- place.address,
                categoryColumn <- place.category.rawValue,
                isVisitedColumn <- place.isVisited,
                plannedDateColumn <- place.plannedDate,
                notesColumn <- place.notes
            ))
            logger.info("Updated place: \(place.id)")
            return true
        } catch {
            logger.error("Failed to update place: \(error)")
            return false
        }
    }

    func toggleVisited(id: UUID) -> Bool {
        guard let place = fetchById(id: id) else {
            logger.error("Failed to toggle visited status: place not found")
            return false
        }

        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                isVisitedColumn <- !place.isVisited
            ))
            logger.info("Toggled visited status for place: \(id)")
            return true
        } catch {
            logger.error("Failed to toggle visited status: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted place: \(id)")
            return true
        } catch {
            logger.error("Failed to delete place: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted places for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete places for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all places")
            return true
        } catch {
            logger.error("Failed to delete all places: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count places: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count places for journey: \(error)")
            return 0
        }
    }

    func countVisited(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString && isVisitedColumn == true).count)
        } catch {
            logger.error("Failed to count visited places: \(error)")
            return 0
        }
    }

    private func mapRowToPlace(_ row: Row) -> PlaceToVisit? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]),
              let category = PlaceCategory(rawValue: row[categoryColumn]) else {
            return nil
        }

        return PlaceToVisit(
            id: id,
            journeyId: journeyId,
            name: row[nameColumn],
            address: row[addressColumn],
            category: category,
            isVisited: row[isVisitedColumn],
            plannedDate: row[plannedDateColumn],
            notes: row[notesColumn],
            createdAt: row[createdAtColumn]
        )
    }
}
