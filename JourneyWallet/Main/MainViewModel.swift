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

    // Basic Stats
    var totalJourneysCount: Int = 0
    var upcomingTripsCount: Int = 0
    var totalDestinations: Int = 0

    // Extended Stats
    var overviewStats: OverviewStatistics?
    var transportStats: TransportStatistics?
    var expenseStats: ExpenseStatistics?
    var totalTravelDays: Int = 0
    var longestJourney: Journey?
    var mostVisitedDestination: (destination: String, count: Int)?

    private let journeysRepository: JourneysRepository?
    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let placesToVisitRepository: PlacesToVisitRepository?
    private let notesRepository: NotesRepository?
    private let documentsRepository: DocumentsRepository?
    private let searchService: SearchService
    private let statisticsService: StatisticsService
    private let logger: Logger

    init(
        databaseManager: DatabaseManager = .shared,
        searchService: SearchService = .shared,
        statisticsService: StatisticsService = .shared
    ) {
        self.journeysRepository = databaseManager.journeysRepository
        self.transportsRepository = databaseManager.transportsRepository
        self.hotelsRepository = databaseManager.hotelsRepository
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.placesToVisitRepository = databaseManager.placesToVisitRepository
        self.notesRepository = databaseManager.notesRepository
        self.documentsRepository = databaseManager.documentsRepository
        self.searchService = searchService
        self.statisticsService = statisticsService
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "MainViewModel")
    }

    func loadData() {
        isLoading = true

        journeys = journeysRepository?.fetchAll() ?? []
        activeJourneys = journeysRepository?.fetchActive() ?? []
        upcomingJourneys = journeysRepository?.fetchUpcoming() ?? []

        // Calculate basic stats
        totalJourneysCount = journeys.count
        upcomingTripsCount = upcomingJourneys.count

        // Count unique destinations
        let uniqueDestinations = Set(journeys.map { $0.destination.lowercased() })
        totalDestinations = uniqueDestinations.count

        // Load extended statistics
        loadExtendedStatistics()

        isLoading = false
        logger.info("Loaded \(self.journeys.count) journeys")
    }

    func loadExtendedStatistics() {
        overviewStats = statisticsService.getOverviewStatistics()
        transportStats = statisticsService.getTransportStatistics()
        expenseStats = statisticsService.getExpenseStatistics()
        totalTravelDays = statisticsService.getTotalTravelDays()
        longestJourney = statisticsService.getLongestJourney()
        mostVisitedDestination = statisticsService.getMostVisitedDestination()

        logger.info("Extended statistics loaded")
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

    // MARK: - Entity Lookups for Search Results

    func getJourney(by id: UUID) -> Journey? {
        journeysRepository?.fetchById(id: id)
    }

    func getTransport(by id: UUID) -> Transport? {
        transportsRepository?.fetchById(id: id)
    }

    func getHotel(by id: UUID) -> Hotel? {
        hotelsRepository?.fetchById(id: id)
    }

    func getCarRental(by id: UUID) -> CarRental? {
        carRentalsRepository?.fetchById(id: id)
    }

    func getPlace(by id: UUID) -> PlaceToVisit? {
        placesToVisitRepository?.fetchById(id: id)
    }

    func getNote(by id: UUID) -> Note? {
        notesRepository?.fetchById(id: id)
    }

    func getDocument(by id: UUID) -> Document? {
        documentsRepository?.fetchById(id: id)
    }
}
