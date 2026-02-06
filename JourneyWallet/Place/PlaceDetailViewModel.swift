import Foundation
import os

@MainActor
@Observable
class PlaceDetailViewModel {

    // MARK: - Properties

    var place: PlaceToVisit
    let journeyId: UUID
    var roadmapAttachment: RoadmapStopAttachment?
    var attachedStopTitle: String?

    // MARK: - Repositories

    private let placesRepository: PlacesToVisitRepository?
    private let roadmapStopAttachmentsRepository: RoadmapStopAttachmentsRepository?
    private let roadmapStopsRepository: RoadmapStopsRepository?
    private let logger: Logger

    // MARK: - Init

    init(place: PlaceToVisit, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.place = place
        self.journeyId = journeyId
        self.placesRepository = databaseManager.placesToVisitRepository
        self.roadmapStopAttachmentsRepository = databaseManager.roadmapStopAttachmentsRepository
        self.roadmapStopsRepository = databaseManager.roadmapStopsRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "PlaceDetailViewModel")
        loadRoadmapAttachment()
    }

    // MARK: - Public Methods

    func updatePlace(_ updatedPlace: PlaceToVisit) {
        if placesRepository?.update(updatedPlace) == true {
            place = updatedPlace
            if let refreshed = placesRepository?.fetchById(id: place.id) {
                place = refreshed
            }
            logger.info("Updated place: \(self.place.id)")
        } else {
            logger.error("Failed to update place: \(self.place.id)")
        }
    }

    func deletePlace() -> Bool {
        if placesRepository?.delete(id: place.id) == true {
            logger.info("Deleted place: \(self.place.id)")
            return true
        } else {
            logger.error("Failed to delete place: \(self.place.id)")
            return false
        }
    }

    func toggleVisited() {
        if placesRepository?.toggleVisited(id: place.id) == true {
            place.isVisited.toggle()
            if let refreshed = placesRepository?.fetchById(id: place.id) {
                place = refreshed
            }
            logger.info("Toggled visited status for place: \(self.place.id)")
        } else {
            logger.error("Failed to toggle visited status for place: \(self.place.id)")
        }
    }

    func moveToJourney(_ newJourneyId: UUID) -> Bool {
        guard placesRepository?.updateJourneyId(id: place.id, newJourneyId: newJourneyId) == true else {
            logger.error("Failed to move place to new journey")
            return false
        }

        logger.info("Moved place \(self.place.id) to journey \(newJourneyId)")
        return true
    }

    func loadRoadmapAttachment() {
        roadmapAttachment = roadmapStopAttachmentsRepository?.fetchByEntityId(
            entityId: place.id,
            entityType: RoadmapEntityType.placeToVisit.rawValue
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
            logger.info("Detached place from roadmap: \(self.place.id)")
        }
    }
}
