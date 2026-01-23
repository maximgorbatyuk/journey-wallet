import Foundation
import os

/// Service for managing reminders and their associated system notifications.
/// Follows the pattern: schedule notification first to get ID, then create reminder with that ID.
class ReminderService {

    static let shared = ReminderService()

    private let remindersRepository: RemindersRepository?
    private let notificationManager: NotificationManager
    private let logger: Logger

    init(
        remindersRepository: RemindersRepository? = nil,
        notificationManager: NotificationManager = NotificationManager.shared
    ) {
        self.remindersRepository = remindersRepository ?? DatabaseManager.shared.remindersRepository
        self.notificationManager = notificationManager
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ReminderService")
    }

    // MARK: - Create Reminder

    /// Creates a new reminder with an associated system notification.
    /// - Parameters:
    ///   - journeyId: The journey this reminder belongs to
    ///   - title: The reminder title
    ///   - reminderDate: When to trigger the reminder
    ///   - relatedEntityType: Optional entity type this reminder is related to
    ///   - relatedEntityId: Optional entity ID this reminder is related to
    /// - Returns: The created reminder with notification ID, or nil if failed
    @discardableResult
    func createReminder(
        journeyId: UUID,
        title: String,
        reminderDate: Date,
        relatedEntityType: ReminderEntityType? = nil,
        relatedEntityId: UUID? = nil
    ) -> Reminder? {
        // Step 1: Schedule the notification first to get the notification ID
        let notificationId = notificationManager.scheduleNotification(
            title: L("reminder.notification.title"),
            body: title,
            on: reminderDate
        )

        logger.info("Scheduled notification with ID: \(notificationId)")

        // Step 2: Create the reminder entity with the notification ID
        let reminder = Reminder(
            journeyId: journeyId,
            title: title,
            reminderDate: reminderDate,
            relatedEntityType: relatedEntityType,
            relatedEntityId: relatedEntityId,
            notificationId: notificationId
        )

        // Step 3: Insert into database
        let success = remindersRepository?.insert(reminder) ?? false

        if success {
            logger.info("Created reminder: \(reminder.id)")
            return reminder
        } else {
            // Rollback: cancel the notification if database insert failed
            notificationManager.cancelNotification(notificationId)
            logger.error("Failed to create reminder, cancelled notification")
            return nil
        }
    }

    // MARK: - Update Reminder

    /// Updates an existing reminder and reschedules its notification if needed.
    /// - Parameter reminder: The reminder to update
    /// - Returns: True if successful
    @discardableResult
    func updateReminder(_ reminder: Reminder) -> Bool {
        // Cancel old notification if exists
        if let oldReminder = remindersRepository?.fetchById(id: reminder.id),
           let oldNotificationId = oldReminder.notificationId {
            notificationManager.cancelNotification(oldNotificationId)
            logger.info("Cancelled old notification: \(oldNotificationId)")
        }

        var updatedReminder = reminder

        // Schedule new notification if not completed and date is in the future
        if !reminder.isCompleted && reminder.reminderDate > Date() {
            let notificationId = notificationManager.scheduleNotification(
                title: L("reminder.notification.title"),
                body: reminder.title,
                on: reminder.reminderDate
            )
            updatedReminder.notificationId = notificationId
            logger.info("Scheduled new notification: \(notificationId)")
        } else {
            updatedReminder.notificationId = nil
        }

        return remindersRepository?.update(updatedReminder) ?? false
    }

    // MARK: - Delete Reminder

    /// Deletes a reminder and cancels its associated notification.
    /// - Parameter id: The reminder ID to delete
    /// - Returns: True if successful
    @discardableResult
    func deleteReminder(id: UUID) -> Bool {
        // Get the reminder to find its notification ID
        if let reminder = remindersRepository?.fetchById(id: id),
           let notificationId = reminder.notificationId {
            notificationManager.cancelNotification(notificationId)
            logger.info("Cancelled notification: \(notificationId)")
        }

        return remindersRepository?.delete(id: id) ?? false
    }

    // MARK: - Mark Complete/Incomplete

    /// Marks a reminder as completed and cancels its notification.
    /// - Parameter id: The reminder ID
    /// - Returns: True if successful
    @discardableResult
    func markCompleted(id: UUID) -> Bool {
        // Cancel notification
        if let reminder = remindersRepository?.fetchById(id: id),
           let notificationId = reminder.notificationId {
            notificationManager.cancelNotification(notificationId)
            logger.info("Cancelled notification for completed reminder: \(notificationId)")
        }

        return remindersRepository?.markCompleted(id: id) ?? false
    }

    /// Marks a reminder as incomplete and reschedules notification if date is in the future.
    /// - Parameter id: The reminder ID
    /// - Returns: True if successful
    @discardableResult
    func markIncomplete(id: UUID) -> Bool {
        guard let reminder = remindersRepository?.fetchById(id: id) else {
            return false
        }

        // Reschedule notification if date is in the future
        if reminder.reminderDate > Date() {
            let notificationId = notificationManager.scheduleNotification(
                title: L("reminder.notification.title"),
                body: reminder.title,
                on: reminder.reminderDate
            )

            var updatedReminder = reminder
            updatedReminder.isCompleted = false
            updatedReminder.notificationId = notificationId

            return remindersRepository?.update(updatedReminder) ?? false
        } else {
            return remindersRepository?.markIncomplete(id: id) ?? false
        }
    }

    // MARK: - Bulk Operations

    /// Deletes all reminders for a journey and cancels their notifications.
    /// - Parameter journeyId: The journey ID
    /// - Returns: True if successful
    @discardableResult
    func deleteRemindersForJourney(journeyId: UUID) -> Bool {
        // Get all reminders for the journey
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []

        // Cancel all notifications
        for reminder in reminders {
            if let notificationId = reminder.notificationId {
                notificationManager.cancelNotification(notificationId)
            }
        }

        return remindersRepository?.deleteByJourneyId(journeyId: journeyId) ?? false
    }

    /// Deletes all reminders for a related entity and cancels their notifications.
    /// - Parameters:
    ///   - type: The entity type
    ///   - entityId: The entity ID
    /// - Returns: True if successful
    @discardableResult
    func deleteRemindersForEntity(type: ReminderEntityType, entityId: UUID) -> Bool {
        let reminders = remindersRepository?.fetchByRelatedEntity(type: type, entityId: entityId) ?? []

        for reminder in reminders {
            if let notificationId = reminder.notificationId {
                notificationManager.cancelNotification(notificationId)
            }
        }

        return remindersRepository?.deleteByRelatedEntity(type: type, entityId: entityId) ?? false
    }

    // MARK: - Transport Reminder Helpers

    /// Creates a reminder for a transport departure.
    /// - Parameters:
    ///   - transport: The transport entity
    ///   - hoursBeforeDeparture: Hours before departure to remind
    /// - Returns: The created reminder, or nil if failed
    @discardableResult
    func createTransportReminder(
        transport: Transport,
        hoursBeforeDeparture: Int
    ) -> Reminder? {
        let reminderDate = transport.departureDate.addingTimeInterval(-Double(hoursBeforeDeparture * 3600))

        guard reminderDate > Date() else {
            logger.warning("Cannot create reminder for past date")
            return nil
        }

        let title = String(format: L("reminder.transport.title_format"),
                          transport.type.displayName,
                          transport.departureLocation,
                          hoursBeforeDeparture)

        return createReminder(
            journeyId: transport.journeyId,
            title: title,
            reminderDate: reminderDate,
            relatedEntityType: .transport,
            relatedEntityId: transport.id
        )
    }

    // MARK: - Hotel Reminder Helpers

    /// Creates a reminder for hotel check-in.
    /// - Parameters:
    ///   - hotel: The hotel entity
    ///   - daysBeforeCheckIn: Days before check-in to remind
    /// - Returns: The created reminder, or nil if failed
    @discardableResult
    func createHotelReminder(
        hotel: Hotel,
        daysBeforeCheckIn: Int
    ) -> Reminder? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: hotel.checkInDate)
        components.day! -= daysBeforeCheckIn
        components.hour = 9
        components.minute = 0

        guard let reminderDate = Calendar.current.date(from: components),
              reminderDate > Date() else {
            logger.warning("Cannot create reminder for past date")
            return nil
        }

        let title = String(format: L("reminder.hotel.title_format"),
                          hotel.name,
                          daysBeforeCheckIn)

        return createReminder(
            journeyId: hotel.journeyId,
            title: title,
            reminderDate: reminderDate,
            relatedEntityType: .hotel,
            relatedEntityId: hotel.id
        )
    }

    // MARK: - Car Rental Reminder Helpers

    /// Creates a reminder for car rental pickup.
    /// - Parameters:
    ///   - carRental: The car rental entity
    ///   - daysBeforePickup: Days before pickup to remind
    /// - Returns: The created reminder, or nil if failed
    @discardableResult
    func createCarRentalReminder(
        carRental: CarRental,
        daysBeforePickup: Int
    ) -> Reminder? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: carRental.pickupDate)
        components.day! -= daysBeforePickup
        components.hour = 9
        components.minute = 0

        guard let reminderDate = Calendar.current.date(from: components),
              reminderDate > Date() else {
            logger.warning("Cannot create reminder for past date")
            return nil
        }

        let title = String(format: L("reminder.car_rental.title_format"),
                           carRental.displayName,
                           daysBeforePickup)

        return createReminder(
            journeyId: carRental.journeyId,
            title: title,
            reminderDate: reminderDate,
            relatedEntityType: .carRental,
            relatedEntityId: carRental.id
        )
    }
}
