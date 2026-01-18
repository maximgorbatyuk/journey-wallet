import Foundation
import os

enum JourneyFilter: String, CaseIterable {
    case all
    case active
    case upcoming
    case past

    var displayName: String {
        switch self {
        case .all: return L("journey.filter.all")
        case .active: return L("journey.filter.active")
        case .upcoming: return L("journey.filter.upcoming")
        case .past: return L("journey.filter.past")
        }
    }
}

@MainActor
@Observable
class JourneysListViewModel {

    var journeys: [Journey] = []
    var filteredJourneys: [Journey] = []
    var selectedFilter: JourneyFilter = .all
    var isLoading: Bool = false
    var showAddJourneySheet: Bool = false
    var journeyToEdit: Journey?

    private let journeysRepository: JourneysRepository?
    private let logger: Logger

    init(databaseManager: DatabaseManager = .shared) {
        self.journeysRepository = databaseManager.journeysRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "JourneysListViewModel")
    }

    func loadJourneys() {
        isLoading = true
        journeys = journeysRepository?.fetchAll() ?? []
        applyFilter()
        isLoading = false
        logger.info("Loaded \(self.journeys.count) journeys")
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredJourneys = journeys
        case .active:
            filteredJourneys = journeys.filter { $0.isActive }
        case .upcoming:
            filteredJourneys = journeys.filter { $0.isUpcoming }
        case .past:
            filteredJourneys = journeys.filter { $0.isPast }
        }
    }

    func deleteJourney(_ journey: Journey) {
        guard journeysRepository?.delete(id: journey.id) == true else {
            logger.error("Failed to delete journey \(journey.id)")
            return
        }

        journeys.removeAll { $0.id == journey.id }
        applyFilter()
        logger.info("Deleted journey \(journey.id)")
    }

    func addJourney(_ journey: Journey) {
        guard journeysRepository?.insert(journey) == true else {
            logger.error("Failed to insert journey")
            return
        }

        journeys.insert(journey, at: 0)
        journeys.sort { $0.startDate > $1.startDate }
        applyFilter()
        logger.info("Added journey \(journey.id)")
    }

    func updateJourney(_ journey: Journey) {
        guard journeysRepository?.update(journey) == true else {
            logger.error("Failed to update journey \(journey.id)")
            return
        }

        if let index = journeys.firstIndex(where: { $0.id == journey.id }) {
            journeys[index] = journey
        }
        journeys.sort { $0.startDate > $1.startDate }
        applyFilter()
        logger.info("Updated journey \(journey.id)")
    }
}
