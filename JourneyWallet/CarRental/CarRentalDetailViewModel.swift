import Foundation
import os

@MainActor
@Observable
class CarRentalDetailViewModel {

    // MARK: - Properties

    var carRental: CarRental
    let journeyId: UUID

    // MARK: - Repositories

    private let carRentalsRepository: CarRentalsRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    // MARK: - Init

    init(carRental: CarRental, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.carRental = carRental
        self.journeyId = journeyId
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "CarRentalDetailViewModel")
    }

    // MARK: - Public Methods

    func updateCarRental(_ updatedCarRental: CarRental) {
        if carRentalsRepository?.update(updatedCarRental) == true {
            carRental = updatedCarRental
            logger.info("Updated car rental: \(updatedCarRental.id)")
        } else {
            logger.error("Failed to update car rental: \(updatedCarRental.id)")
        }
    }

    func deleteCarRental() -> Bool {
        // Delete associated reminders first
        deleteRemindersForCarRental()

        // Delete car rental
        if carRentalsRepository?.delete(id: carRental.id) == true {
            logger.info("Deleted car rental: \(self.carRental.id)")
            return true
        } else {
            logger.error("Failed to delete car rental: \(self.carRental.id)")
            return false
        }
    }

    func saveReminder(date: Date, title: String) {
        // Schedule local notification first to get the notificationId
        let notificationId = NotificationManager.shared.scheduleNotification(
            title: L("car_rental.reminder.notification.title"),
            body: title,
            on: date
        )

        // Create Reminder entity with the notificationId
        let reminder = Reminder(
            journeyId: journeyId,
            title: title,
            reminderDate: date,
            relatedEntityId: carRental.id,
            notificationId: notificationId
        )

        if remindersRepository?.insert(reminder) == true {
            logger.info("Added reminder for car rental: \(self.carRental.id)")
        } else {
            logger.error("Failed to add reminder for car rental: \(self.carRental.id)")
        }
    }

    // MARK: - Private Methods

    private func deleteRemindersForCarRental() {
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == carRental.id {
            if let notificationId = reminder.notificationId {
                NotificationManager.shared.cancelNotification(notificationId)
            }
            _ = remindersRepository?.delete(id: reminder.id)
        }
    }
}
