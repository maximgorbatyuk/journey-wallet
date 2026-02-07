import Foundation
import os
import SQLite

class RoadmapStopAttachmentsRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let roadmapStopIdColumn = Expression<String>("roadmap_stop_id")
    private let entityTypeColumn = Expression<String>("entity_type")
    private let entityIdColumn = Expression<String>("entity_id")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "RoadmapStopAttachmentsRepository")
    }

    func fetchAll() -> [RoadmapStopAttachment] {
        var attachments: [RoadmapStopAttachment] = []

        do {
            for row in try db.prepare(table.order(createdAtColumn.asc)) {
                if let attachment = mapRowToAttachment(row) {
                    attachments.append(attachment)
                }
            }
        } catch {
            logger.error("Failed to fetch all roadmap stop attachments: \(error)")
        }

        return attachments
    }

    func fetchById(id: UUID) -> RoadmapStopAttachment? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToAttachment(row)
            }
        } catch {
            logger.error("Failed to fetch roadmap stop attachment by id \(id): \(error)")
        }
        return nil
    }

    func fetchByStopId(stopId: UUID) -> [RoadmapStopAttachment] {
        var attachments: [RoadmapStopAttachment] = []

        do {
            let query = table
                .filter(roadmapStopIdColumn == stopId.uuidString)
                .order(createdAtColumn.asc)
            for row in try db.prepare(query) {
                if let attachment = mapRowToAttachment(row) {
                    attachments.append(attachment)
                }
            }
        } catch {
            logger.error("Failed to fetch attachments for stop \(stopId): \(error)")
        }

        return attachments
    }

    func fetchByEntityId(entityId: UUID, entityType: String) -> RoadmapStopAttachment? {
        let query = table.filter(
            entityIdColumn == entityId.uuidString && entityTypeColumn == entityType
        )
        do {
            if let row = try db.pluck(query) {
                return mapRowToAttachment(row)
            }
        } catch {
            logger.error("Failed to fetch attachment for entity \(entityId): \(error)")
        }
        return nil
    }

    func insert(_ attachment: RoadmapStopAttachment) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- attachment.id.uuidString,
                roadmapStopIdColumn <- attachment.roadmapStopId.uuidString,
                entityTypeColumn <- attachment.entityType,
                entityIdColumn <- attachment.entityId.uuidString,
                createdAtColumn <- attachment.createdAt
            )
            try db.run(insert)
            logger.info("Inserted roadmap stop attachment: \(attachment.id)")
            return true
        } catch {
            logger.error("Failed to insert roadmap stop attachment: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted roadmap stop attachment: \(id)")
            return true
        } catch {
            logger.error("Failed to delete roadmap stop attachment: \(error)")
            return false
        }
    }

    func deleteByStopId(stopId: UUID) -> Bool {
        let records = table.filter(roadmapStopIdColumn == stopId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted attachments for stop: \(stopId)")
            return true
        } catch {
            logger.error("Failed to delete attachments for stop: \(error)")
            return false
        }
    }

    func deleteByEntityId(entityId: UUID) -> Bool {
        let records = table.filter(entityIdColumn == entityId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted attachments for entity: \(entityId)")
            return true
        } catch {
            logger.error("Failed to delete attachments for entity: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all roadmap stop attachments")
            return true
        } catch {
            logger.error("Failed to delete all roadmap stop attachments: \(error)")
            return false
        }
    }

    private func mapRowToAttachment(_ row: Row) -> RoadmapStopAttachment? {
        guard let id = UUID(uuidString: row[idColumn]),
              let roadmapStopId = UUID(uuidString: row[roadmapStopIdColumn]),
              let entityId = UUID(uuidString: row[entityIdColumn]) else {
            return nil
        }

        return RoadmapStopAttachment(
            id: id,
            roadmapStopId: roadmapStopId,
            entityType: row[entityTypeColumn],
            entityId: entityId,
            createdAt: row[createdAtColumn]
        )
    }
}
