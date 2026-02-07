import Foundation
import os

@MainActor
@Observable
class CarRentalDetailViewModel {

    // MARK: - Properties

    var carRental: CarRental
    let journeyId: UUID
    var roadmapAttachment: RoadmapStopAttachment?
    var attachedStopTitle: String?

    // MARK: - Repositories

    private let carRentalsRepository: CarRentalsRepository?
    private let journeysRepository: JourneysRepository?
    private let remindersRepository: RemindersRepository?
    private let roadmapStopAttachmentsRepository: RoadmapStopAttachmentsRepository?
    private let roadmapStopsRepository: RoadmapStopsRepository?
    private let logger: Logger

    // MARK: - Init

    init(carRental: CarRental, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.carRental = carRental
        self.journeyId = journeyId
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.roadmapStopAttachmentsRepository = databaseManager.roadmapStopAttachmentsRepository
        self.roadmapStopsRepository = databaseManager.roadmapStopsRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "CarRentalDetailViewModel")
        loadRoadmapAttachment()
    }

    // MARK: - Public Methods

    func updateCarRental(_ updatedCarRental: CarRental) {
        if carRentalsRepository?.update(updatedCarRental) == true {
            carRental = updatedCarRental
            if let refreshed = carRentalsRepository?.fetchById(id: carRental.id) {
                carRental = refreshed
            }
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
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
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
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
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            logger.info("Added reminder for car rental: \(self.carRental.id)")
        } else {
            logger.error("Failed to add reminder for car rental: \(self.carRental.id)")
        }
    }

    func moveToJourney(_ newJourneyId: UUID) -> Bool {
        // Move the main entity
        guard carRentalsRepository?.updateJourneyId(id: carRental.id, newJourneyId: newJourneyId) == true else {
            logger.error("Failed to move car rental to new journey")
            return false
        }

        // Move associated reminders
        moveRemindersToJourney(newJourneyId)

        journeysRepository?.touchUpdatedAt(journeyId: journeyId)
        journeysRepository?.touchUpdatedAt(journeyId: newJourneyId)
        logger.info("Moved car rental \(self.carRental.id) to journey \(newJourneyId)")
        return true
    }

    private func moveRemindersToJourney(_ newJourneyId: UUID) {
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == carRental.id {
            _ = remindersRepository?.updateJourneyId(id: reminder.id, newJourneyId: newJourneyId)
        }
    }

    func loadRoadmapAttachment() {
        roadmapAttachment = roadmapStopAttachmentsRepository?.fetchByEntityId(
            entityId: carRental.id,
            entityType: RoadmapEntityType.carRental.rawValue
        )
        if let attachment = roadmapAttachment,
           let stop = roadmapStopsRepository?.fetchById(id: attachment.roadmapStopId) {
            attachedStopTitle = stop.title
        } else {
            attachedStopTitle = nil
        }
    }

    func detachFromRoadmap() {
        guard let attachment = roadmapAttachment else { return }
        if roadmapStopAttachmentsRepository?.delete(id: attachment.id) == true {
            roadmapAttachment = nil
            attachedStopTitle = nil
            logger.info("Detached car rental from roadmap: \(self.carRental.id)")
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
