import Foundation
import os

/// Filter options for places list
enum PlaceFilter: String, CaseIterable {
    case all
    case toVisit
    case visited

    var displayName: String {
        switch self {
        case .all: return L("place.filter.all")
        case .toVisit: return L("place.filter.to_visit")
        case .visited: return L("place.filter.visited")
        }
    }
}

@MainActor
@Observable
class PlaceListViewModel {

    // MARK: - Properties

    var places: [PlaceToVisit] = []
    var filteredPlaces: [PlaceToVisit] = []
    var selectedFilter: PlaceFilter = .all
    var selectedCategory: PlaceCategory? = nil
    var isLoading: Bool = false

    var showAddPlaceSheet: Bool = false
    var placeToEdit: PlaceToVisit? = nil

    let journeyId: UUID

    // MARK: - Repositories

    private let placesRepository: PlacesToVisitRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.placesRepository = databaseManager.placesToVisitRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "PlaceListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true
        places = placesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        applyFilters()
        isLoading = false
    }

    func applyFilters() {
        var result = places

        // Apply visited filter
        switch selectedFilter {
        case .all:
            break
        case .toVisit:
            result = result.filter { !$0.isVisited }
        case .visited:
            result = result.filter { $0.isVisited }
        }

        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Sort: unvisited first by planned date, then visited
        filteredPlaces = result.sorted { place1, place2 in
            if place1.isVisited != place2.isVisited {
                return !place1.isVisited
            }
            if let date1 = place1.plannedDate, let date2 = place2.plannedDate {
                return date1 < date2
            }
            if place1.plannedDate != nil { return true }
            if place2.plannedDate != nil { return false }
            return place1.name < place2.name
        }
    }

    func addPlace(_ place: PlaceToVisit) {
        if placesRepository?.insert(place) == true {
            logger.info("Added place: \(place.id)")
            loadData()
        }
    }

    func updatePlace(_ place: PlaceToVisit) {
        if placesRepository?.update(place) == true {
            logger.info("Updated place: \(place.id)")
            loadData()
        }
    }

    func deletePlace(_ place: PlaceToVisit) {
        if placesRepository?.delete(id: place.id) == true {
            logger.info("Deleted place: \(place.id)")
            loadData()
        }
    }

    func toggleVisited(_ place: PlaceToVisit) {
        if placesRepository?.toggleVisited(id: place.id) == true {
            logger.info("Toggled visited status for place: \(place.id)")
            loadData()
        }
    }

    // MARK: - Computed Properties

    var totalCount: Int {
        filteredPlaces.count
    }

    var visitedCount: Int {
        places.filter { $0.isVisited }.count
    }

    var toVisitCount: Int {
        places.filter { !$0.isVisited }.count
    }

    var progressPercentage: Double {
        guard !places.isEmpty else { return 0 }
        return Double(visitedCount) / Double(places.count) * 100
    }
}
