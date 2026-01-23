import Foundation
import os

/// Service for calculating travel statistics and insights
class StatisticsService {

    static let shared = StatisticsService()

    private let journeysRepository: JourneysRepository?
    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let expensesRepository: ExpensesRepository?
    private let placesToVisitRepository: PlacesToVisitRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    init(databaseManager: DatabaseManager = .shared) {
        self.journeysRepository = databaseManager.journeysRepository
        self.transportsRepository = databaseManager.transportsRepository
        self.hotelsRepository = databaseManager.hotelsRepository
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.expensesRepository = databaseManager.expensesRepository
        self.placesToVisitRepository = databaseManager.placesToVisitRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "StatisticsService")
    }

    // MARK: - Journey Statistics

    /// Get overview statistics for the dashboard
    func getOverviewStatistics() -> OverviewStatistics {
        let journeys = journeysRepository?.fetchAll() ?? []
        let activeJourneys = journeysRepository?.fetchActive() ?? []
        let upcomingJourneys = journeysRepository?.fetchUpcoming() ?? []
        let pastJourneys = journeysRepository?.fetchPast() ?? []

        let uniqueDestinations = Set(journeys.map { $0.destination.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })

        return OverviewStatistics(
            totalJourneys: journeys.count,
            activeJourneys: activeJourneys.count,
            upcomingJourneys: upcomingJourneys.count,
            pastJourneys: pastJourneys.count,
            uniqueDestinations: uniqueDestinations.count
        )
    }

    /// Get total travel days across all journeys
    func getTotalTravelDays() -> Int {
        let journeys = journeysRepository?.fetchAll() ?? []
        return journeys.reduce(0) { $0 + $1.durationDays }
    }

    /// Get the longest journey
    func getLongestJourney() -> Journey? {
        let journeys = journeysRepository?.fetchAll() ?? []
        return journeys.max(by: { $0.durationDays < $1.durationDays })
    }

    /// Get most visited destination
    func getMostVisitedDestination() -> (destination: String, count: Int)? {
        let journeys = journeysRepository?.fetchAll() ?? []
        let destinationCounts = Dictionary(grouping: journeys, by: { $0.destination.lowercased() })
            .mapValues { $0.count }

        guard let (destination, count) = destinationCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }

        // Capitalize first letter
        let formattedDestination = destination.prefix(1).uppercased() + destination.dropFirst()
        return (formattedDestination, count)
    }

    // MARK: - Transport Statistics

    /// Get transport statistics
    func getTransportStatistics() -> TransportStatistics {
        let transports = transportsRepository?.fetchAll() ?? []

        let byType = Dictionary(grouping: transports, by: { $0.type })
            .mapValues { $0.count }

        let totalFlights = byType[.flight] ?? 0
        let totalTrains = byType[.train] ?? 0
        let totalBuses = byType[.bus] ?? 0
        let totalFerries = byType[.ferry] ?? 0
        let totalTransfers = byType[.transfer] ?? 0
        let totalOther = byType[.other] ?? 0

        return TransportStatistics(
            totalTransports: transports.count,
            flights: totalFlights,
            trains: totalTrains,
            buses: totalBuses,
            ferries: totalFerries,
            transfers: totalTransfers,
            other: totalOther
        )
    }

    // MARK: - Accommodation Statistics

    /// Get hotel/accommodation statistics
    func getAccommodationStatistics() -> AccommodationStatistics {
        let hotels = hotelsRepository?.fetchAll() ?? []

        let totalNights = hotels.reduce(0) { total, hotel in
            let nights = Calendar.current.dateComponents([.day], from: hotel.checkInDate, to: hotel.checkOutDate).day ?? 0
            return total + nights
        }

        return AccommodationStatistics(
            totalHotels: hotels.count,
            totalNights: totalNights
        )
    }

    /// Get car rental statistics
    func getCarRentalStatistics() -> CarRentalStatistics {
        let rentals = carRentalsRepository?.fetchAll() ?? []

        let totalDays = rentals.reduce(0) { total, rental in
            let days = Calendar.current.dateComponents([.day], from: rental.pickupDate, to: rental.dropoffDate).day ?? 0
            return total + max(days, 1)
        }

        return CarRentalStatistics(
            totalRentals: rentals.count,
            totalDays: totalDays
        )
    }

    // MARK: - Expense Statistics

    /// Get expense statistics
    func getExpenseStatistics() -> ExpenseStatistics {
        let expenses = expensesRepository?.fetchAll() ?? []

        var totalByCurrency: [Currency: Decimal] = [:]
        var totalByCategory: [ExpenseCategory: Decimal] = [:]

        for expense in expenses {
            totalByCurrency[expense.currency, default: 0] += expense.amount
            totalByCategory[expense.category, default: 0] += expense.amount
        }

        // Find primary currency (most used)
        let primaryCurrency = totalByCurrency.max(by: { $0.value < $1.value })?.key ?? .usd
        let totalInPrimaryCurrency = totalByCurrency[primaryCurrency] ?? 0

        return ExpenseStatistics(
            totalExpenses: expenses.count,
            totalAmount: totalInPrimaryCurrency,
            primaryCurrency: primaryCurrency,
            totalByCurrency: totalByCurrency,
            totalByCategory: totalByCategory
        )
    }

    /// Get expense statistics for a specific journey
    func getExpenseStatisticsForJourney(journeyId: UUID) -> ExpenseStatistics {
        let expenses = expensesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []

        var totalByCurrency: [Currency: Decimal] = [:]
        var totalByCategory: [ExpenseCategory: Decimal] = [:]

        for expense in expenses {
            totalByCurrency[expense.currency, default: 0] += expense.amount
            totalByCategory[expense.category, default: 0] += expense.amount
        }

        let primaryCurrency = totalByCurrency.max(by: { $0.value < $1.value })?.key ?? .usd
        let totalInPrimaryCurrency = totalByCurrency[primaryCurrency] ?? 0

        return ExpenseStatistics(
            totalExpenses: expenses.count,
            totalAmount: totalInPrimaryCurrency,
            primaryCurrency: primaryCurrency,
            totalByCurrency: totalByCurrency,
            totalByCategory: totalByCategory
        )
    }

    // MARK: - Places Statistics

    /// Get places to visit statistics
    func getPlacesStatistics() -> PlacesStatistics {
        let places = placesToVisitRepository?.fetchAll() ?? []

        let visited = places.filter { $0.isVisited }.count
        let toVisit = places.filter { !$0.isVisited }.count

        let byCategory = Dictionary(grouping: places, by: { $0.category })
            .mapValues { $0.count }

        return PlacesStatistics(
            totalPlaces: places.count,
            visited: visited,
            toVisit: toVisit,
            byCategory: byCategory
        )
    }

    // MARK: - Reminder Statistics

    /// Get reminder statistics
    func getReminderStatistics() -> ReminderStatistics {
        let reminders = remindersRepository?.fetchAll() ?? []

        let completed = reminders.filter { $0.isCompleted }.count
        let pending = reminders.filter { !$0.isCompleted }.count
        let overdue = reminders.filter { $0.isOverdue }.count

        return ReminderStatistics(
            totalReminders: reminders.count,
            completed: completed,
            pending: pending,
            overdue: overdue
        )
    }

    // MARK: - Journey Details Statistics

    /// Get comprehensive statistics for a specific journey
    func getJourneyDetailStatistics(journeyId: UUID) -> JourneyDetailStatistics {
        let transports = transportsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let hotels = hotelsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let carRentals = carRentalsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let places = placesToVisitRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let expenses = expensesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []

        let placesVisited = places.filter { $0.isVisited }.count
        let remindersCompleted = reminders.filter { $0.isCompleted }.count

        // Calculate total spent
        var totalSpent: Decimal = 0
        var primaryCurrency: Currency = .usd

        if !expenses.isEmpty {
            let byCurrency = Dictionary(grouping: expenses, by: { $0.currency })
                .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amount } }

            if let (currency, amount) = byCurrency.max(by: { $0.value < $1.value }) {
                primaryCurrency = currency
                totalSpent = amount
            }
        }

        return JourneyDetailStatistics(
            transportsCount: transports.count,
            hotelsCount: hotels.count,
            carRentalsCount: carRentals.count,
            placesCount: places.count,
            placesVisited: placesVisited,
            remindersCount: reminders.count,
            remindersCompleted: remindersCompleted,
            expensesCount: expenses.count,
            totalSpent: totalSpent,
            spentCurrency: primaryCurrency
        )
    }

    // MARK: - Time-based Statistics

    /// Get journeys by year
    func getJourneysByYear() -> [Int: Int] {
        let journeys = journeysRepository?.fetchAll() ?? []
        let calendar = Calendar.current

        return Dictionary(grouping: journeys) { journey in
            calendar.component(.year, from: journey.startDate)
        }.mapValues { $0.count }
    }

    /// Get journeys by month for a specific year
    func getJourneysByMonth(year: Int) -> [Int: Int] {
        let journeys = journeysRepository?.fetchAll() ?? []
        let calendar = Calendar.current

        let journeysInYear = journeys.filter {
            calendar.component(.year, from: $0.startDate) == year
        }

        return Dictionary(grouping: journeysInYear) { journey in
            calendar.component(.month, from: journey.startDate)
        }.mapValues { $0.count }
    }
}

// MARK: - Statistics Models

struct OverviewStatistics {
    let totalJourneys: Int
    let activeJourneys: Int
    let upcomingJourneys: Int
    let pastJourneys: Int
    let uniqueDestinations: Int
}

struct TransportStatistics {
    let totalTransports: Int
    let flights: Int
    let trains: Int
    let buses: Int
    let ferries: Int
    let transfers: Int
    let other: Int

    var breakdown: [(type: TransportType, count: Int)] {
        [
            (.flight, flights),
            (.train, trains),
            (.bus, buses),
            (.ferry, ferries),
            (.transfer, transfers),
            (.other, other)
        ].filter { $0.count > 0 }
    }
}

struct AccommodationStatistics {
    let totalHotels: Int
    let totalNights: Int
}

struct CarRentalStatistics {
    let totalRentals: Int
    let totalDays: Int
}

struct ExpenseStatistics {
    let totalExpenses: Int
    let totalAmount: Decimal
    let primaryCurrency: Currency
    let totalByCurrency: [Currency: Decimal]
    let totalByCategory: [ExpenseCategory: Decimal]

    var categoryBreakdown: [(category: ExpenseCategory, amount: Decimal)] {
        totalByCategory
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }
}

struct PlacesStatistics {
    let totalPlaces: Int
    let visited: Int
    let toVisit: Int
    let byCategory: [PlaceCategory: Int]

    var visitedPercentage: Double {
        guard totalPlaces > 0 else { return 0 }
        return Double(visited) / Double(totalPlaces) * 100
    }
}

struct ReminderStatistics {
    let totalReminders: Int
    let completed: Int
    let pending: Int
    let overdue: Int

    var completionPercentage: Double {
        guard totalReminders > 0 else { return 0 }
        return Double(completed) / Double(totalReminders) * 100
    }
}

struct JourneyDetailStatistics {
    let transportsCount: Int
    let hotelsCount: Int
    let carRentalsCount: Int
    let placesCount: Int
    let placesVisited: Int
    let remindersCount: Int
    let remindersCompleted: Int
    let expensesCount: Int
    let totalSpent: Decimal
    let spentCurrency: Currency

    var totalItems: Int {
        transportsCount + hotelsCount + carRentalsCount + placesCount + remindersCount + expensesCount
    }
}
