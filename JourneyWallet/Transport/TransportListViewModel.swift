import Foundation
import os

/// Filter options for transport list
enum TransportFilter: String, CaseIterable {
    case all
    case upcoming
    case inProgress
    case past

    var displayName: String {
        switch self {
        case .all: return L("transport.filter.all")
        case .upcoming: return L("transport.filter.upcoming")
        case .inProgress: return L("transport.filter.in_progress")
        case .past: return L("transport.filter.past")
        }
    }
}

@MainActor
@Observable
class TransportListViewModel {

    // MARK: - Properties

    var transports: [Transport] = []
    var filteredTransports: [Transport] = []
    var selectedFilter: TransportFilter = .all
    var selectedTypeFilter: TransportType? = nil
    var isLoading: Bool = false

    var showAddTransportSheet: Bool = false
    var transportToEdit: Transport? = nil
    var transportToView: Transport? = nil

    let journeyId: UUID
    var journey: Journey?

    // MARK: - Repositories

    private let transportsRepository: TransportsRepository?
    private let journeysRepository: JourneysRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.transportsRepository = databaseManager.transportsRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "TransportListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true

        journey = journeysRepository?.fetchById(id: journeyId)
        transports = transportsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        applyFilters()

        isLoading = false
    }

    func applyFilters() {
        var result = transports

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            result = result.filter { $0.isUpcoming }
        case .inProgress:
            result = result.filter { $0.isInProgress }
        case .past:
            result = result.filter { $0.isPast }
        }

        // Apply type filter
        if let typeFilter = selectedTypeFilter {
            result = result.filter { $0.type == typeFilter }
        }

        filteredTransports = result
    }

    func addTransport(_ transport: Transport) {
        if transportsRepository?.insert(transport) == true {
            logger.info("Added transport: \(transport.id)")
            loadData()
        }
    }

    func updateTransport(_ transport: Transport) {
        if transportsRepository?.update(transport) == true {
            logger.info("Updated transport: \(transport.id)")
            loadData()
        }
    }

    func deleteTransport(_ transport: Transport) {
        // Delete associated reminders
        deleteRemindersForTransport(transport.id)

        if transportsRepository?.delete(id: transport.id) == true {
            logger.info("Deleted transport: \(transport.id)")
            loadData()
        }
    }

    // MARK: - Grouping

    /// Returns transports grouped by type
    var transportsByType: [TransportType: [Transport]] {
        Dictionary(grouping: filteredTransports, by: { $0.type })
    }

    /// Returns sorted transport types that have items
    var activeTypes: [TransportType] {
        TransportType.allCases.filter { transportsByType[$0]?.isEmpty == false }
    }

    // MARK: - Private Methods

    private func deleteRemindersForTransport(_ transportId: UUID) {
        // Get all reminders for this transport and delete them
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == transportId {
            _ = remindersRepository?.delete(id: reminder.id)
        }
    }
}
