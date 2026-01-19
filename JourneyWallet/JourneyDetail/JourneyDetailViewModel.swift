import Foundation
import os

/// Summary counts for all journey sections
struct JourneySectionCounts {
    var transports: Int = 0
    var hotels: Int = 0
    var carRentals: Int = 0
    var documents: Int = 0
    var notes: Int = 0
    var places: Int = 0
    var reminders: Int = 0
    var expenses: Int = 0
    var totalExpenses: Decimal = 0
    var expensesCurrency: Currency?
}

@MainActor
@Observable
class JourneyDetailViewModel {

    // MARK: - Properties

    var allJourneys: [Journey] = []
    var selectedJourneyId: UUID?
    var selectedJourney: Journey?
    var sectionCounts = JourneySectionCounts()
    var isLoading: Bool = false

    // Preview data for sections (limited items)
    var upcomingTransports: [Transport] = []
    var upcomingHotels: [Hotel] = []
    var upcomingCarRentals: [CarRental] = []
    var recentNotes: [Note] = []
    var upcomingPlaces: [PlaceToVisit] = []
    var upcomingReminders: [Reminder] = []
    var recentExpenses: [Expense] = []

    // MARK: - Repositories

    private let journeysRepository: JourneysRepository?
    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let documentsRepository: DocumentsRepository?
    private let notesRepository: NotesRepository?
    private let placesToVisitRepository: PlacesToVisitRepository?
    private let remindersRepository: RemindersRepository?
    private let expensesRepository: ExpensesRepository?
    private let userSettingsRepository: UserSettingsRepository?

    private let logger: Logger

    // MARK: - UserDefaults key for persisting selected journey

    private let selectedJourneyKey = "selectedJourneyId"

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.journeysRepository = databaseManager.journeysRepository
        self.transportsRepository = databaseManager.transportsRepository
        self.hotelsRepository = databaseManager.hotelsRepository
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.documentsRepository = databaseManager.documentsRepository
        self.notesRepository = databaseManager.notesRepository
        self.placesToVisitRepository = databaseManager.placesToVisitRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.expensesRepository = databaseManager.expensesRepository
        self.userSettingsRepository = databaseManager.userSettingsRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "JourneyDetailViewModel")
    }

    // MARK: - Public Methods

    func loadInitialData() {
        isLoading = true

        // Load all journeys for the selector
        allJourneys = journeysRepository?.fetchAll() ?? []

        // Restore previously selected journey or select most recent active/upcoming
        if let savedIdString = UserDefaults.standard.string(forKey: selectedJourneyKey),
           let savedId = UUID(uuidString: savedIdString),
           allJourneys.contains(where: { $0.id == savedId }) {
            selectJourney(id: savedId)
        } else {
            // Select most relevant journey (active > upcoming > most recent)
            let activeJourney = allJourneys.first(where: { $0.isActive })
            let upcomingJourney = allJourneys.first(where: { $0.isUpcoming })
            let mostRecentJourney = allJourneys.first

            if let journey = activeJourney ?? upcomingJourney ?? mostRecentJourney {
                selectJourney(id: journey.id)
            }
        }

        isLoading = false
    }

    func selectJourney(id: UUID) {
        selectedJourneyId = id
        selectedJourney = journeysRepository?.fetchById(id: id)

        // Persist selection
        UserDefaults.standard.set(id.uuidString, forKey: selectedJourneyKey)

        // Load all section data
        loadSectionData()
    }

    func refreshData() {
        allJourneys = journeysRepository?.fetchAll() ?? []

        // Verify selected journey still exists
        if let selectedId = selectedJourneyId,
           !allJourneys.contains(where: { $0.id == selectedId }) {
            // Selected journey was deleted, select another
            selectedJourneyId = nil
            selectedJourney = nil

            if let firstJourney = allJourneys.first {
                selectJourney(id: firstJourney.id)
            }
        } else if let selectedId = selectedJourneyId {
            loadSectionData()
            selectedJourney = journeysRepository?.fetchById(id: selectedId)
        }
    }

    // MARK: - Private Methods

    private func loadSectionData() {
        guard let journeyId = selectedJourneyId else {
            resetSectionData()
            return
        }

        // Load counts
        sectionCounts.transports = transportsRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.hotels = hotelsRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.carRentals = carRentalsRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.documents = documentsRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.notes = notesRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.places = placesToVisitRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.reminders = remindersRepository?.countByJourneyId(journeyId: journeyId) ?? 0
        sectionCounts.expenses = expensesRepository?.countByJourneyId(journeyId: journeyId) ?? 0

        // Calculate total expenses and get recent ones
        let expenses = expensesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        sectionCounts.totalExpenses = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        sectionCounts.expensesCurrency = expenses.first?.currency ?? userSettingsRepository?.fetchCurrency()

        // Get 3 most recent expenses (sorted by date descending)
        recentExpenses = Array(expenses.sorted { $0.date > $1.date }.prefix(3))

        // Load preview items (first 3 of each)
        let allTransports = transportsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        upcomingTransports = Array(allTransports.filter { $0.isUpcoming || $0.isInProgress }.prefix(3))

        let allHotels = hotelsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        upcomingHotels = Array(allHotels.filter { $0.isUpcoming || $0.isActive }.prefix(3))

        let allCarRentals = carRentalsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        upcomingCarRentals = Array(allCarRentals.filter { $0.isUpcoming || $0.isActive }.prefix(3))

        recentNotes = Array((notesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []).prefix(3))

        let allPlaces = placesToVisitRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        upcomingPlaces = Array(allPlaces.filter { !$0.isVisited }.prefix(3))

        let allReminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        upcomingReminders = Array(allReminders.filter { !$0.isCompleted }.prefix(3))

        logger.info("Loaded section data for journey \(journeyId)")
    }

    private func resetSectionData() {
        sectionCounts = JourneySectionCounts()
        upcomingTransports = []
        upcomingHotels = []
        upcomingCarRentals = []
        recentNotes = []
        upcomingPlaces = []
        upcomingReminders = []
        recentExpenses = []
    }
}
