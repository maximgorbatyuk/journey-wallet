import Foundation
import os
import SQLite

class Migration_20260206_RoadmapTables {

    private let migrationName = "20260206_RoadmapTables"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try createRoadmapStopsTable(logger: logger)
            try createRoadmapStopAttachmentsTable(logger: logger)

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func createRoadmapStopsTable(logger: Logger) throws {
        let table = Table("roadmap_stops")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let title = Expression<String>("title")
        let subtitle = Expression<String?>("subtitle")
        let arrivalDate = Expression<Date?>("arrival_date")
        let departureDate = Expression<Date?>("departure_date")
        let sortOrder = Expression<Int>("sort_order")
        let outgoingTransportId = Expression<String?>("outgoing_transport_id")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(title)
            t.column(subtitle)
            t.column(arrivalDate)
            t.column(departureDate)
            t.column(sortOrder, defaultValue: 0)
            t.column(outgoingTransportId)
            t.column(notes)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Roadmap stops table created successfully")
    }

    private func createRoadmapStopAttachmentsTable(logger: Logger) throws {
        let table = Table("roadmap_stop_attachments")

        let id = Expression<String>("id")
        let roadmapStopId = Expression<String>("roadmap_stop_id")
        let entityType = Expression<String>("entity_type")
        let entityId = Expression<String>("entity_id")
        let createdAt = Expression<Date>("created_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(roadmapStopId)
            t.column(entityType)
            t.column(entityId)
            t.column(createdAt)
        })

        try db.run(table.createIndex(roadmapStopId, ifNotExists: true))
        try db.run(table.createIndex(entityId, ifNotExists: true))
        try db.run(table.createIndex(roadmapStopId, entityType, entityId, unique: true, ifNotExists: true))

        logger.debug("Roadmap stop attachments table created successfully")
    }
}
