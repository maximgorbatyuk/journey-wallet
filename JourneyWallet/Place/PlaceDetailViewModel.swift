import Foundation
import os

@MainActor
@Observable
class PlaceDetailViewModel {

    // MARK: - Properties

    var place: PlaceToVisit
    let journeyId: UUID

    // MARK: - Repositories

    private let placesRepository: PlacesToVisitRepository?
    private let logger: Logger

    // MARK: - Init

    init(place: PlaceToVisit, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.place = place
        self.journeyId = journeyId
        self.placesRepository = databaseManager.placesToVisitRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "PlaceDetailViewModel")
    }

    // MARK: - Public Methods

    func updatePlace(_ updatedPlace: PlaceToVisit) {
        if placesRepository?.update(updatedPlace) == true {
            place = updatedPlace
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
}
