import Foundation
import SQLite
import os

class RemindersRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let titleColumn = Expression<String>("title")
    private let reminderDateColumn = Expression<Date>("reminder_date")
    private let isCompletedColumn = Expression<Bool>("is_completed")
    private let relatedEntityTypeColumn = Expression<String?>("related_entity_type")
    private let relatedEntityIdColumn = Expression<String?>("related_entity_id")
    private let notificationIdColumn = Expression<String?>("notification_id")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "RemindersRepository")
    }

    func fetchAll() -> [Reminder] {
        var reminders: [Reminder] = []

        do {
            for row in try db.prepare(table.order(reminderDateColumn.asc)) {
                if let reminder = mapRowToReminder(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch all reminders: \(error)")
        }

        return reminders
    }

    func fetchByJourneyId(journeyId: UUID) -> [Reminder] {
        var reminders: [Reminder] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(reminderDateColumn.asc)
            for row in try db.prepare(query) {
                if let reminder = mapRowToReminder(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch reminders for journey \(journeyId): \(error)")
        }

        return reminders
    }

    func fetchById(id: UUID) -> Reminder? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToReminder(row)
            }
        } catch {
            logger.error("Failed to fetch reminder by id \(id): \(error)")
        }
        return nil
    }

    func fetchUpcoming() -> [Reminder] {
        var reminders: [Reminder] = []
        let now = Date()

        do {
            let query = table.filter(reminderDateColumn > now && isCompletedColumn == false).order(reminderDateColumn.asc)
            for row in try db.prepare(query) {
                if let reminder = mapRowToReminder(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch upcoming reminders: \(error)")
        }

        return reminders
    }

    func fetchIncomplete() -> [Reminder] {
        var reminders: [Reminder] = []

        do {
            let query = table.filter(isCompletedColumn == false).order(reminderDateColumn.asc)
            for row in try db.prepare(query) {
                if let reminder = mapRowToReminder(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch incomplete reminders: \(error)")
        }

        return reminders
    }

    func fetchOverdue() -> [Reminder] {
        var reminders: [Reminder] = []
        let now = Date()

        do {
            let query = table.filter(reminderDateColumn < now && isCompletedColumn == false).order(reminderDateColumn.asc)
            for row in try db.prepare(query) {
                if let reminder = mapRowToReminder(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch overdue reminders: \(error)")
        }

        return reminders
    }

    func fetchByRelatedEntity(type: ReminderEntityType, entityId: UUID) -> [Reminder] {
        var reminders: [Reminder] = []

        do {
            let query = table.filter(
                relatedEntityTypeColumn == type.rawValue && relatedEntityIdColumn == entityId.uuidString
            ).order(reminderDateColumn.asc)

            for row in try db.prepare(query) {
                if let reminder = mapRowToReminder(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch reminders for entity: \(error)")
        }

        return reminders
    }

    func fetchByNotificationId(notificationId: String) -> Reminder? {
        let query = table.filter(notificationIdColumn == notificationId)
        do {
            if let row = try db.pluck(query) {
                return mapRowToReminder(row)
            }
        } catch {
            logger.error("Failed to fetch reminder by notification id: \(error)")
        }
        return nil
    }

    func insert(_ reminder: Reminder) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- reminder.id.uuidString,
                journeyIdColumn <- reminder.journeyId.uuidString,
                titleColumn <- reminder.title,
                reminderDateColumn <- reminder.reminderDate,
                isCompletedColumn <- reminder.isCompleted,
                relatedEntityTypeColumn <- reminder.relatedEntityType?.rawValue,
                relatedEntityIdColumn <- reminder.relatedEntityId?.uuidString,
                notificationIdColumn <- reminder.notificationId,
                createdAtColumn <- reminder.createdAt
            )
            try db.run(insert)
            logger.info("Inserted reminder: \(reminder.id)")
            return true
        } catch {
            logger.error("Failed to insert reminder: \(error)")
            return false
        }
    }

    func update(_ reminder: Reminder) -> Bool {
        let record = table.filter(idColumn == reminder.id.uuidString)

        do {
            try db.run(record.update(
                titleColumn <- reminder.title,
                reminderDateColumn <- reminder.reminderDate,
                isCompletedColumn <- reminder.isCompleted,
                relatedEntityTypeColumn <- reminder.relatedEntityType?.rawValue,
                relatedEntityIdColumn <- reminder.relatedEntityId?.uuidString,
                notificationIdColumn <- reminder.notificationId
            ))
            logger.info("Updated reminder: \(reminder.id)")
            return true
        } catch {
            logger.error("Failed to update reminder: \(error)")
            return false
        }
    }

    func markCompleted(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                isCompletedColumn <- true
            ))
            logger.info("Marked reminder as completed: \(id)")
            return true
        } catch {
            logger.error("Failed to mark reminder as completed: \(error)")
            return false
        }
    }

    func markIncomplete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.update(
                isCompletedColumn <- false
            ))
            logger.info("Marked reminder as incomplete: \(id)")
            return true
        } catch {
            logger.error("Failed to mark reminder as incomplete: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted reminder: \(id)")
            return true
        } catch {
            logger.error("Failed to delete reminder: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted reminders for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete reminders for journey: \(error)")
            return false
        }
    }

    func deleteByRelatedEntity(type: ReminderEntityType, entityId: UUID) -> Bool {
        let records = table.filter(
            relatedEntityTypeColumn == type.rawValue && relatedEntityIdColumn == entityId.uuidString
        )

        do {
            try db.run(records.delete())
            logger.info("Deleted reminders for entity: \(entityId)")
            return true
        } catch {
            logger.error("Failed to delete reminders for entity: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all reminders")
            return true
        } catch {
            logger.error("Failed to delete all reminders: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count reminders: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count reminders for journey: \(error)")
            return 0
        }
    }

    func countIncomplete() -> Int {
        do {
            return try db.scalar(table.filter(isCompletedColumn == false).count)
        } catch {
            logger.error("Failed to count incomplete reminders: \(error)")
            return 0
        }
    }

    private func mapRowToReminder(_ row: Row) -> Reminder? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]) else {
            return nil
        }

        var relatedEntityType: ReminderEntityType?
        if let typeString = row[relatedEntityTypeColumn] {
            relatedEntityType = ReminderEntityType(rawValue: typeString)
        }

        var relatedEntityId: UUID?
        if let idString = row[relatedEntityIdColumn] {
            relatedEntityId = UUID(uuidString: idString)
        }

        return Reminder(
            id: id,
            journeyId: journeyId,
            title: row[titleColumn],
            reminderDate: row[reminderDateColumn],
            isCompleted: row[isCompletedColumn],
            relatedEntityType: relatedEntityType,
            relatedEntityId: relatedEntityId,
            notificationId: row[notificationIdColumn],
            createdAt: row[createdAtColumn]
        )
    }
}
