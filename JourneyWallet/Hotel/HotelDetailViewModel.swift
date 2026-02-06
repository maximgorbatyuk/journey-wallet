import Foundation
import os

@MainActor
@Observable
class HotelDetailViewModel {

    // MARK: - Properties

    var hotel: Hotel
    let journeyId: UUID
    var roadmapAttachment: RoadmapStopAttachment?
    var attachedStopTitle: String?

    // MARK: - Repositories

    private let hotelsRepository: HotelsRepository?
    private let remindersRepository: RemindersRepository?
    private let roadmapStopAttachmentsRepository: RoadmapStopAttachmentsRepository?
    private let roadmapStopsRepository: RoadmapStopsRepository?
    private let logger: Logger

    // MARK: - Init

    init(hotel: Hotel, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.hotel = hotel
        self.journeyId = journeyId
        self.hotelsRepository = databaseManager.hotelsRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.roadmapStopAttachmentsRepository = databaseManager.roadmapStopAttachmentsRepository
        self.roadmapStopsRepository = databaseManager.roadmapStopsRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "HotelDetailViewModel")
        loadRoadmapAttachment()
    }

    // MARK: - Public Methods

    func updateHotel(_ updatedHotel: Hotel) {
        if hotelsRepository?.update(updatedHotel) == true {
            hotel = updatedHotel
            logger.info("Updated hotel: \(self.hotel.id)")
        } else {
            logger.error("Failed to update hotel: \(self.hotel.id)")
        }
    }

    func deleteHotel() -> Bool {
        // Delete associated reminders first
        deleteRemindersForHotel()

        // Delete hotel
        if hotelsRepository?.delete(id: hotel.id) == true {
            logger.info("Deleted hotel: \(self.hotel.id)")
            return true
        } else {
            logger.error("Failed to delete hotel: \(self.hotel.id)")
            return false
        }
    }

    func saveReminder(date: Date, title: String) {
        // Schedule local notification first to get the notificationId
        let notificationId = NotificationManager.shared.scheduleNotification(
            title: L("hotel.reminder.notification.title"),
            body: title,
            on: date
        )

        // Create Reminder entity with the notificationId
        let reminder = Reminder(
            journeyId: journeyId,
            title: title,
            reminderDate: date,
            relatedEntityId: hotel.id,
            notificationId: notificationId
        )

        if remindersRepository?.insert(reminder) == true {
            logger.info("Added reminder for hotel: \(self.hotel.id)")
        } else {
            logger.error("Failed to add reminder for hotel: \(self.hotel.id)")
        }
    }

    func moveToJourney(_ newJourneyId: UUID) -> Bool {
        // Move the main entity
        guard hotelsRepository?.updateJourneyId(id: hotel.id, newJourneyId: newJourneyId) == true else {
            logger.error("Failed to move hotel to new journey")
            return false
        }

        // Move associated reminders
        moveRemindersToJourney(newJourneyId)

        logger.info("Moved hotel \(self.hotel.id) to journey \(newJourneyId)")
        return true
    }

    private func moveRemindersToJourney(_ newJourneyId: UUID) {
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == hotel.id {
            _ = remindersRepository?.updateJourneyId(id: reminder.id, newJourneyId: newJourneyId)
        }
    }

    func loadRoadmapAttachment() {
        roadmapAttachment = roadmapStopAttachmentsRepository?.fetchByEntityId(
            entityId: hotel.id,
            entityType: RoadmapEntityType.hotel.rawValue
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
            logger.info("Detached hotel from roadmap: \(self.hotel.id)")
        }
    }

    // MARK: - Private Methods

    private func deleteRemindersForHotel() {
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == hotel.id {
            if let notificationId = reminder.notificationId {
                NotificationManager.shared.cancelNotification(notificationId)
            }
            _ = remindersRepository?.delete(id: reminder.id)
        }
    }
}
