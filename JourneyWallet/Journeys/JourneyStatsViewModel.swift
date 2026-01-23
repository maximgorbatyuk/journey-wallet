import Foundation
import os

@MainActor
@Observable
class JourneyStatsViewModel {
    let journey: Journey

    private(set) var flightsCount: Int = 0
    private(set) var trainsCount: Int = 0
    private(set) var otherTransportsCount: Int = 0
    private(set) var hotelsCount: Int = 0
    private(set) var carRentalsCount: Int = 0
    private(set) var documentsCount: Int = 0
    private(set) var placesCount: Int = 0
    private(set) var notesCount: Int = 0

    private(set) var isLoading: Bool = true

    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let documentsRepository: DocumentsRepository?
    private let placesRepository: PlacesToVisitRepository?
    private let notesRepository: NotesRepository?
    private let logger: Logger

    init(journey: Journey, databaseManager: DatabaseManager = .shared) {
        self.journey = journey
        self.transportsRepository = databaseManager.transportsRepository
        self.hotelsRepository = databaseManager.hotelsRepository
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.documentsRepository = databaseManager.documentsRepository
        self.placesRepository = databaseManager.placesToVisitRepository
        self.notesRepository = databaseManager.notesRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "JourneyStatsViewModel")
    }

    func loadStats() {
        isLoading = true

        // Load transports
        let transports = transportsRepository?.fetchByJourneyId(journeyId: journey.id) ?? []
        flightsCount = transports.filter { $0.type == TransportType.flight }.count
        trainsCount = transports.filter { $0.type == TransportType.train }.count
        otherTransportsCount = transports.filter { $0.type != TransportType.flight && $0.type != TransportType.train }.count

        // Load hotels
        hotelsCount = hotelsRepository?.fetchByJourneyId(journeyId: journey.id).count ?? 0

        // Load car rentals
        carRentalsCount = carRentalsRepository?.fetchByJourneyId(journeyId: journey.id).count ?? 0

        // Load documents
        documentsCount = documentsRepository?.fetchByJourneyId(journeyId: journey.id).count ?? 0

        // Load places
        placesCount = placesRepository?.fetchByJourneyId(journeyId: journey.id).count ?? 0

        // Load notes
        notesCount = notesRepository?.fetchByJourneyId(journeyId: journey.id).count ?? 0

        isLoading = false
    }
}
