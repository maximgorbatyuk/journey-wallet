import Foundation
import os
import SQLite

class RoadmapStopsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let titleColumn = Expression<String>("title")
    private let subtitleColumn = Expression<String?>("subtitle")
    private let arrivalDateColumn = Expression<Date?>("arrival_date")
    private let departureDateColumn = Expression<Date?>("departure_date")
    private let sortOrderColumn = Expression<Int>("sort_order")
    private let outgoingTransportIdColumn = Expression<String?>("outgoing_transport_id")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "RoadmapStopsRepository")
    }

    func fetchAll() -> [RoadmapStop] {
        var stops: [RoadmapStop] = []

        do {
            for row in try db.prepare(table.order(sortOrderColumn.asc)) {
                if let stop = mapRowToStop(row) {
                    stops.append(stop)
                }
            }
        } catch {
            logger.error("Failed to fetch all roadmap stops: \(error)")
        }

        return stops
    }

    func fetchByJourneyId(journeyId: UUID) -> [RoadmapStop] {
        var stops: [RoadmapStop] = []

        do {
            let query = table
                .filter(journeyIdColumn == journeyId.uuidString)
                .order(sortOrderColumn.asc)
            for row in try db.prepare(query) {
                if let stop = mapRowToStop(row) {
                    stops.append(stop)
                }
            }
        } catch {
            logger.error("Failed to fetch roadmap stops for journey \(journeyId): \(error)")
        }

        return stops
    }

    func fetchById(id: UUID) -> RoadmapStop? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToStop(row)
            }
        } catch {
            logger.error("Failed to fetch roadmap stop by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ stop: RoadmapStop) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- stop.id.uuidString,
                journeyIdColumn <- stop.journeyId.uuidString,
                titleColumn <- stop.title,
                subtitleColumn <- stop.subtitle,
                arrivalDateColumn <- stop.arrivalDate,
                departureDateColumn <- stop.departureDate,
                sortOrderColumn <- stop.sortOrder,
                outgoingTransportIdColumn <- stop.outgoingTransportId?.uuidString,
                notesColumn <- stop.notes,
                createdAtColumn <- stop.createdAt,
                updatedAtColumn <- stop.updatedAt
            )
            try db.run(insert)
            logger.info("Inserted roadmap stop: \(stop.id)")
            return true
        } catch {
            logger.error("Failed to insert roadmap stop: \(error)")
            return false
        }
    }

    func update(_ stop: RoadmapStop) -> Bool {
        let record = table.filter(idColumn == stop.id.uuidString)

        do {
            try db.run(record.update(
                titleColumn <- stop.title,
                subtitleColumn <- stop.subtitle,
                arrivalDateColumn <- stop.arrivalDate,
                departureDateColumn <- stop.departureDate,
                sortOrderColumn <- stop.sortOrder,
                outgoingTransportIdColumn <- stop.outgoingTransportId?.uuidString,
                notesColumn <- stop.notes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated roadmap stop: \(stop.id)")
            return true
        } catch {
            logger.error("Failed to update roadmap stop: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted roadmap stop: \(id)")
            return true
        } catch {
            logger.error("Failed to delete roadmap stop: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted roadmap stops for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete roadmap stops for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all roadmap stops")
            return true
        } catch {
            logger.error("Failed to delete all roadmap stops: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count roadmap stops: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count roadmap stops for journey: \(error)")
            return 0
        }
    }

    func updateJourneyId(id: UUID, newJourneyId: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                journeyIdColumn <- newJourneyId.uuidString,
                updatedAtColumn <- Date()
            ))
            logger.info("Moved roadmap stop \(id) to journey \(newJourneyId)")
            return true
        } catch {
            logger.error("Failed to move roadmap stop: \(error)")
            return false
        }
    }

    func updateSortOrders(_ stops: [(id: UUID, sortOrder: Int)]) -> Bool {
        do {
            try db.transaction {
                for item in stops {
                    let record = table.filter(idColumn == item.id.uuidString)
                    try db.run(record.update(
                        sortOrderColumn <- item.sortOrder,
                        updatedAtColumn <- Date()
                    ))
                }
            }
            logger.info("Updated sort orders for \(stops.count) roadmap stops")
            return true
        } catch {
            logger.error("Failed to update sort orders: \(error)")
            return false
        }
    }

    func updateOutgoingTransportId(id: UUID, transportId: UUID?) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                outgoingTransportIdColumn <- transportId?.uuidString,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated outgoing transport for roadmap stop: \(id)")
            return true
        } catch {
            logger.error("Failed to update outgoing transport: \(error)")
            return false
        }
    }

    private func mapRowToStop(_ row: Row) -> RoadmapStop? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]) else {
            return nil
        }

        let outgoingTransportId: UUID? = if let transportIdString = row[outgoingTransportIdColumn] {
            UUID(uuidString: transportIdString)
        } else {
            nil
        }

        return RoadmapStop(
            id: id,
            journeyId: journeyId,
            title: row[titleColumn],
            subtitle: row[subtitleColumn],
            arrivalDate: row[arrivalDateColumn],
            departureDate: row[departureDateColumn],
            sortOrder: row[sortOrderColumn],
            outgoingTransportId: outgoingTransportId,
            notes: row[notesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
