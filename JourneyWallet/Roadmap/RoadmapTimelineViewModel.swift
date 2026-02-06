import Foundation
import os
import SwiftUI

@MainActor
@Observable
class RoadmapTimelineViewModel {

    // MARK: - Properties

    var allJourneys: [Journey] = []
    var selectedJourneyId: UUID?
    var stops: [RoadmapStop] = []
    var attachmentsByStopId: [UUID: [RoadmapStopAttachment]] = [:]
    var transportsByStopId: [UUID: Transport] = [:]
    var isLoading: Bool = false

    var selectedJourney: Journey? {
        allJourneys.first(where: { $0.id == selectedJourneyId })
    }

    // MARK: - Entity name lookups for display

    var hotelNames: [UUID: String] = [:]
    var transportNames: [UUID: String] = [:]
    var carRentalNames: [UUID: String] = [:]
    var placeNames: [UUID: String] = [:]
    var ideaNames: [UUID: String] = [:]

    // MARK: - Repositories

    private let journeysRepository: JourneysRepository?
    private let roadmapStopsRepository: RoadmapStopsRepository?
    private let roadmapStopAttachmentsRepository: RoadmapStopAttachmentsRepository?
    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let placesToVisitRepository: PlacesToVisitRepository?
    private let ideasRepository: IdeasRepository?
    private let logger: Logger

    private let selectedJourneyKey = "selectedRoadmapJourneyId"

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.journeysRepository = databaseManager.journeysRepository
        self.roadmapStopsRepository = databaseManager.roadmapStopsRepository
        self.roadmapStopAttachmentsRepository = databaseManager.roadmapStopAttachmentsRepository
        self.transportsRepository = databaseManager.transportsRepository
        self.hotelsRepository = databaseManager.hotelsRepository
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.placesToVisitRepository = databaseManager.placesToVisitRepository
        self.ideasRepository = databaseManager.ideasRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "RoadmapTimelineViewModel")
    }

    // MARK: - Public Methods

    func loadInitialData() {
        isLoading = true
        allJourneys = journeysRepository?.fetchAll() ?? []

        // Restore saved journey selection
        if let savedId = UserDefaults.standard.string(forKey: selectedJourneyKey),
           let uuid = UUID(uuidString: savedId),
           allJourneys.contains(where: { $0.id == uuid }) {
            selectedJourneyId = uuid
        } else if let activeJourney = allJourneys.first(where: { $0.isActive }) {
            selectedJourneyId = activeJourney.id
        } else if let firstJourney = allJourneys.first {
            selectedJourneyId = firstJourney.id
        }

        loadStops()
        isLoading = false
    }

    func selectJourney(id: UUID) {
        selectedJourneyId = id
        UserDefaults.standard.set(id.uuidString, forKey: selectedJourneyKey)
        loadStops()
    }

    func loadStops() {
        guard let journeyId = selectedJourneyId else {
            stops = []
            attachmentsByStopId = [:]
            transportsByStopId = [:]
            return
        }

        stops = roadmapStopsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        loadAttachments()
        loadTransports()
        loadEntityNames()
    }

    func addStop(_ stop: RoadmapStop) {
        if roadmapStopsRepository?.insert(stop) == true {
            loadStops()
            logger.info("Added roadmap stop: \(stop.id)")
        } else {
            logger.error("Failed to add roadmap stop")
        }
    }

    func updateStop(_ stop: RoadmapStop) {
        if roadmapStopsRepository?.update(stop) == true {
            loadStops()
            logger.info("Updated roadmap stop: \(stop.id)")
        } else {
            logger.error("Failed to update roadmap stop")
        }
    }

    func deleteStop(id: UUID) {
        // Delete attachments first
        _ = roadmapStopAttachmentsRepository?.deleteByStopId(stopId: id)

        if roadmapStopsRepository?.delete(id: id) == true {
            loadStops()
            logger.info("Deleted roadmap stop: \(id)")
        } else {
            logger.error("Failed to delete roadmap stop: \(id)")
        }
    }

    func moveStops(from source: IndexSet, to destination: Int) {
        var reordered = stops
        reordered.move(fromOffsets: source, toOffset: destination)

        let updates = reordered.enumerated().map { (index, stop) in
            (id: stop.id, sortOrder: index)
        }

        if roadmapStopsRepository?.updateSortOrders(updates) == true {
            stops = reordered.enumerated().map { (index, stop) in
                var updated = stop
                updated.sortOrder = index
                return updated
            }
            logger.info("Reordered roadmap stops")
        } else {
            logger.error("Failed to reorder roadmap stops")
        }
    }

    func refreshData() {
        allJourneys = journeysRepository?.fetchAll() ?? []
        loadStops()
    }

    func removeAttachment(id: UUID) {
        if roadmapStopAttachmentsRepository?.delete(id: id) == true {
            loadStops()
            logger.info("Removed roadmap stop attachment: \(id)")
        } else {
            logger.error("Failed to remove roadmap stop attachment: \(id)")
        }
    }

    func addAttachments(_ attachments: [RoadmapStopAttachment]) {
        for attachment in attachments {
            _ = roadmapStopAttachmentsRepository?.insert(attachment)
        }
        loadStops()
    }

    func setOutgoingTransport(stopId: UUID, transportId: UUID?) {
        if roadmapStopsRepository?.updateOutgoingTransportId(id: stopId, transportId: transportId) == true {
            loadStops()
        }
    }

    func nextSortOrder() -> Int {
        (stops.last?.sortOrder ?? -1) + 1
    }

    func entityDisplayName(for attachment: RoadmapStopAttachment) -> String {
        switch attachment.entityType {
        case RoadmapEntityType.hotel.rawValue:
            return hotelNames[attachment.entityId] ?? L("roadmap.entity_name")
        case RoadmapEntityType.transport.rawValue:
            return transportNames[attachment.entityId] ?? L("roadmap.entity_name")
        case RoadmapEntityType.carRental.rawValue:
            return carRentalNames[attachment.entityId] ?? L("roadmap.entity_name")
        case RoadmapEntityType.placeToVisit.rawValue:
            return placeNames[attachment.entityId] ?? L("roadmap.entity_name")
        case RoadmapEntityType.idea.rawValue:
            return ideaNames[attachment.entityId] ?? L("roadmap.entity_name")
        default:
            return L("roadmap.entity_name")
        }
    }

    func entityIcon(for entityType: String) -> String {
        switch entityType {
        case RoadmapEntityType.hotel.rawValue: return "building.2.fill"
        case RoadmapEntityType.transport.rawValue: return "airplane"
        case RoadmapEntityType.carRental.rawValue: return "car.fill"
        case RoadmapEntityType.placeToVisit.rawValue: return "mappin.circle.fill"
        case RoadmapEntityType.idea.rawValue: return "lightbulb.fill"
        case RoadmapEntityType.expense.rawValue: return "creditcard.fill"
        default: return "square.fill"
        }
    }

    func entityColor(for entityType: String) -> Color {
        switch entityType {
        case RoadmapEntityType.hotel.rawValue: return .blue
        case RoadmapEntityType.transport.rawValue: return .orange
        case RoadmapEntityType.carRental.rawValue: return .green
        case RoadmapEntityType.placeToVisit.rawValue: return .purple
        case RoadmapEntityType.idea.rawValue: return .yellow
        case RoadmapEntityType.expense.rawValue: return .red
        default: return .gray
        }
    }

    // Available entities for attachment (not already attached to any stop)
    func availableHotels() -> [Hotel] {
        guard let journeyId = selectedJourneyId else { return [] }
        let hotels = hotelsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let attachedIds = allAttachedEntityIds(for: RoadmapEntityType.hotel.rawValue)
        return hotels.filter { !attachedIds.contains($0.id) }
    }

    func availableTransports() -> [Transport] {
        guard let journeyId = selectedJourneyId else { return [] }
        let transports = transportsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let attachedIds = allAttachedEntityIds(for: RoadmapEntityType.transport.rawValue)
        return transports.filter { !attachedIds.contains($0.id) }
    }

    func availableCarRentals() -> [CarRental] {
        guard let journeyId = selectedJourneyId else { return [] }
        let carRentals = carRentalsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let attachedIds = allAttachedEntityIds(for: RoadmapEntityType.carRental.rawValue)
        return carRentals.filter { !attachedIds.contains($0.id) }
    }

    func availablePlaces() -> [PlaceToVisit] {
        guard let journeyId = selectedJourneyId else { return [] }
        let places = placesToVisitRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let attachedIds = allAttachedEntityIds(for: RoadmapEntityType.placeToVisit.rawValue)
        return places.filter { !attachedIds.contains($0.id) }
    }

    func availableIdeas() -> [Idea] {
        guard let journeyId = selectedJourneyId else { return [] }
        let ideas = ideasRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        let attachedIds = allAttachedEntityIds(for: RoadmapEntityType.idea.rawValue)
        return ideas.filter { !attachedIds.contains($0.id) }
    }

    func journeyTransports() -> [Transport] {
        guard let journeyId = selectedJourneyId else { return [] }
        return transportsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
    }

    // MARK: - Private Methods

    private func loadAttachments() {
        attachmentsByStopId = [:]
        for stop in stops {
            let attachments = roadmapStopAttachmentsRepository?.fetchByStopId(stopId: stop.id) ?? []
            if !attachments.isEmpty {
                attachmentsByStopId[stop.id] = attachments
            }
        }
    }

    private func loadTransports() {
        transportsByStopId = [:]
        for stop in stops {
            if let transportId = stop.outgoingTransportId,
               let transport = transportsRepository?.fetchById(id: transportId) {
                transportsByStopId[stop.id] = transport
            }
        }
    }

    private func loadEntityNames() {
        hotelNames = [:]
        transportNames = [:]
        carRentalNames = [:]
        placeNames = [:]
        ideaNames = [:]

        let allAttachments = attachmentsByStopId.values.flatMap { $0 }

        for attachment in allAttachments {
            switch attachment.entityType {
            case RoadmapEntityType.hotel.rawValue:
                if let hotel = hotelsRepository?.fetchById(id: attachment.entityId) {
                    hotelNames[attachment.entityId] = hotel.name
                }
            case RoadmapEntityType.transport.rawValue:
                if let transport = transportsRepository?.fetchById(id: attachment.entityId) {
                    transportNames[attachment.entityId] = "\(transport.departureLocation) → \(transport.arrivalLocation)"
                }
            case RoadmapEntityType.carRental.rawValue:
                if let carRental = carRentalsRepository?.fetchById(id: attachment.entityId) {
                    carRentalNames[attachment.entityId] = carRental.displayName
                }
            case RoadmapEntityType.placeToVisit.rawValue:
                if let place = placesToVisitRepository?.fetchById(id: attachment.entityId) {
                    placeNames[attachment.entityId] = place.name
                }
            case RoadmapEntityType.idea.rawValue:
                if let idea = ideasRepository?.fetchById(id: attachment.entityId) {
                    ideaNames[attachment.entityId] = idea.title
                }
            default:
                break
            }
        }
    }

    private func allAttachedEntityIds(for entityType: String) -> Set<UUID> {
        var ids = Set<UUID>()
        for attachments in attachmentsByStopId.values {
            for attachment in attachments where attachment.entityType == entityType {
                ids.insert(attachment.entityId)
            }
        }
        return ids
    }
}
