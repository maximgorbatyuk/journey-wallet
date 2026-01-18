import Foundation
import os

/// Filter options for car rental list
enum CarRentalFilter: String, CaseIterable {
    case all
    case upcoming
    case active
    case past

    var displayName: String {
        switch self {
        case .all: return L("car_rental.filter.all")
        case .upcoming: return L("car_rental.filter.upcoming")
        case .active: return L("car_rental.filter.active")
        case .past: return L("car_rental.filter.past")
        }
    }
}

@MainActor
@Observable
class CarRentalListViewModel {

    // MARK: - Properties

    var carRentals: [CarRental] = []
    var filteredCarRentals: [CarRental] = []
    var selectedFilter: CarRentalFilter = .all
    var isLoading: Bool = false

    var showAddCarRentalSheet: Bool = false
    var carRentalToEdit: CarRental? = nil
    var carRentalToView: CarRental? = nil

    let journeyId: UUID
    var journey: Journey?

    // MARK: - Repositories

    private let carRentalsRepository: CarRentalsRepository?
    private let journeysRepository: JourneysRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "CarRentalListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true

        journey = journeysRepository?.fetchById(id: journeyId)
        carRentals = carRentalsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        applyFilters()

        isLoading = false
    }

    func applyFilters() {
        var result = carRentals

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

        // Sort by pickup date
        filteredCarRentals = result.sorted { $0.pickupDate < $1.pickupDate }
    }

    func addCarRental(_ carRental: CarRental) {
        if carRentalsRepository?.insert(carRental) == true {
            logger.info("Added car rental: \(carRental.id)")
            loadData()
        }
    }

    func updateCarRental(_ carRental: CarRental) {
        if carRentalsRepository?.update(carRental) == true {
            logger.info("Updated car rental: \(carRental.id)")
            loadData()
        }
    }

    func deleteCarRental(_ carRental: CarRental) {
        // Delete associated reminders
        deleteRemindersForCarRental(carRental.id)

        if carRentalsRepository?.delete(id: carRental.id) == true {
            logger.info("Deleted car rental: \(carRental.id)")
            loadData()
        }
    }

    // MARK: - Computed Properties

    /// Total rental days across all car rentals
    var totalDays: Int {
        filteredCarRentals.reduce(0) { $0 + $1.durationDays }
    }

    /// Total cost across all car rentals (grouped by currency)
    var totalCostByCurrency: [Currency: Decimal] {
        var totals: [Currency: Decimal] = [:]
        for rental in filteredCarRentals {
            if let cost = rental.cost, let currency = rental.currency {
                totals[currency, default: 0] += cost
            }
        }
        return totals
    }

    // MARK: - Private Methods

    private func deleteRemindersForCarRental(_ carRentalId: UUID) {
        // Get all reminders for this car rental and delete them
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == carRentalId {
            _ = remindersRepository?.delete(id: reminder.id)
        }
    }
}
