import Foundation
import os

@MainActor
@Observable
class TransportDetailViewModel {

    // MARK: - Properties

    var transport: Transport
    let journeyId: UUID

    // MARK: - Repositories

    private let transportsRepository: TransportsRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    // MARK: - Init

    init(transport: Transport, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.transport = transport
        self.journeyId = journeyId
        self.transportsRepository = databaseManager.transportsRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "TransportDetailViewModel")
    }

    // MARK: - Public Methods

    func updateTransport(_ updatedTransport: Transport) {
        if transportsRepository?.update(updatedTransport) == true {
            transport = updatedTransport
            logger.info("Updated transport: \(self.transport.id)")
        } else {
            logger.error("Failed to update transport: \(self.transport.id)")
        }
    }

    func deleteTransport() -> Bool {
        // Delete associated reminders first
        deleteRemindersForTransport()

        // Delete transport
        if transportsRepository?.delete(id: transport.id) == true {
            logger.info("Deleted transport: \(self.transport.id)")
            return true
        } else {
            logger.error("Failed to delete transport: \(self.transport.id)")
            return false
        }
    }

    func saveReminder(date: Date, title: String) {
        // Schedule local notification first to get the notificationId
        let notificationId = NotificationManager.shared.scheduleNotification(
            title: L("transport.reminder.notification.title"),
            body: title,
            on: date
        )

        // Create Reminder entity with the notificationId
        let reminder = Reminder(
            journeyId: journeyId,
            title: title,
            reminderDate: date,
            relatedEntityId: transport.id,
            notificationId: notificationId
        )

        if remindersRepository?.insert(reminder) == true {
            logger.info("Added reminder for transport: \(self.transport.id)")
        } else {
            logger.error("Failed to add reminder for transport: \(self.transport.id)")
        }
    }

    // MARK: - Private Methods

    private func deleteRemindersForTransport() {
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == transport.id {
            if let notificationId = reminder.notificationId {
                NotificationManager.shared.cancelNotification(notificationId)
            }
            _ = remindersRepository?.delete(id: reminder.id)
        }
    }
}
