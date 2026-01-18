import Foundation
import os

@MainActor
@Observable
class MainViewModel {

    var journeys: [Journey] = []
    var activeJourneys: [Journey] = []
    var upcomingJourneys: [Journey] = []
    var searchQuery: String = ""
    var searchResults: [SearchResult] = []
    var isSearching: Bool = false
    var isLoading: Bool = false

    // Stats
    var totalJourneysCount: Int = 0
    var upcomingTripsCount: Int = 0
    var totalDestinations: Int = 0

    private let journeysRepository: JourneysRepository?
    private let searchService: SearchService
    private let logger: Logger

    init(
        databaseManager: DatabaseManager = .shared,
        searchService: SearchService = .shared
    ) {
        self.journeysRepository = databaseManager.journeysRepository
        self.searchService = searchService
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "MainViewModel")
    }

    func loadData() {
        isLoading = true

        journeys = journeysRepository?.fetchAll() ?? []
        activeJourneys = journeysRepository?.fetchActive() ?? []
        upcomingJourneys = journeysRepository?.fetchUpcoming() ?? []

        // Calculate stats
        totalJourneysCount = journeys.count
        upcomingTripsCount = upcomingJourneys.count

        // Count unique destinations
        let uniqueDestinations = Set(journeys.map { $0.destination.lowercased() })
        totalDestinations = uniqueDestinations.count

        isLoading = false
        logger.info("Loaded \(self.journeys.count) journeys")
    }

    func search() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchResults = searchService.search(query: searchQuery)
        logger.info("Search for '\(self.searchQuery)' returned \(self.searchResults.count) results")
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
    }

    func getActiveAndUpcomingJourneys() -> [Journey] {
        var combined = activeJourneys
        combined.append(contentsOf: upcomingJourneys.prefix(5))
        return Array(Set(combined)).sorted { $0.startDate < $1.startDate }
    }
}
