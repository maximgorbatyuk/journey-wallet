import Foundation
import os

/// Filter options for hotel list
enum HotelFilter: String, CaseIterable {
    case all
    case upcoming
    case active
    case past

    var displayName: String {
        switch self {
        case .all: return L("hotel.filter.all")
        case .upcoming: return L("hotel.filter.upcoming")
        case .active: return L("hotel.filter.active")
        case .past: return L("hotel.filter.past")
        }
    }
}

@MainActor
@Observable
class HotelListViewModel {

    // MARK: - Properties

    var hotels: [Hotel] = []
    var filteredHotels: [Hotel] = []
    var selectedFilter: HotelFilter = .all
    var isLoading: Bool = false

    var showAddHotelSheet: Bool = false
    var hotelToEdit: Hotel? = nil
    var hotelToView: Hotel? = nil

    let journeyId: UUID
    var journey: Journey?

    // MARK: - Repositories

    private let hotelsRepository: HotelsRepository?
    private let journeysRepository: JourneysRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.hotelsRepository = databaseManager.hotelsRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "HotelListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true

        journey = journeysRepository?.fetchById(id: journeyId)
        hotels = hotelsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        applyFilters()

        isLoading = false
    }

    func applyFilters() {
        var result = hotels

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            result = result.filter { $0.isUpcoming }
        case .active:
            result = result.filter { $0.isActive }
        case .past:
            result = result.filter { $0.isPast }
        }

        // Sort by check-in date
        filteredHotels = result.sorted { $0.checkInDate < $1.checkInDate }
    }

    func addHotel(_ hotel: Hotel) {
        if hotelsRepository?.insert(hotel) == true {
            logger.info("Added hotel: \(hotel.id)")
            loadData()
        }
    }

    func updateHotel(_ hotel: Hotel) {
        if hotelsRepository?.update(hotel) == true {
            logger.info("Updated hotel: \(hotel.id)")
            loadData()
        }
    }

    func deleteHotel(_ hotel: Hotel) {
        // Delete associated reminders
        deleteRemindersForHotel(hotel.id)

        if hotelsRepository?.delete(id: hotel.id) == true {
            logger.info("Deleted hotel: \(hotel.id)")
            loadData()
        }
    }

    // MARK: - Computed Properties

    /// Total nights across all hotels
    var totalNights: Int {
        filteredHotels.reduce(0) { $0 + $1.nightsCount }
    }

    /// Total cost across all hotels (in their original currencies)
    var totalCostByCurrency: [Currency: Decimal] {
        var totals: [Currency: Decimal] = [:]
        for hotel in filteredHotels {
            if let cost = hotel.cost, let currency = hotel.currency {
                totals[currency, default: 0] += cost
            }
        }
        return totals
    }

    // MARK: - Private Methods

    private func deleteRemindersForHotel(_ hotelId: UUID) {
        // Get all reminders for this hotel and delete them
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == hotelId {
            _ = remindersRepository?.delete(id: reminder.id)
        }
    }
}
