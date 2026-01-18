import Foundation
import os

struct SearchResult: Identifiable, Equatable {
    let id: UUID
    let type: SearchResultType
    let title: String
    let subtitle: String?
    let journeyId: UUID?
    let journeyName: String?

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }
}

enum SearchResultType: String, CaseIterable {
    case journey
    case transport
    case hotel
    case carRental
    case place
    case note

    var icon: String {
        switch self {
        case .journey: return "suitcase.fill"
        case .transport: return "airplane"
        case .hotel: return "bed.double.fill"
        case .carRental: return "car.fill"
        case .place: return "mappin"
        case .note: return "note.text"
        }
    }

    var displayName: String {
        switch self {
        case .journey: return L("search.type.journey")
        case .transport: return L("search.type.transport")
        case .hotel: return L("search.type.hotel")
        case .carRental: return L("search.type.car_rental")
        case .place: return L("search.type.place")
        case .note: return L("search.type.note")
        }
    }
}

class SearchService {
    static let shared = SearchService()

    private let journeysRepository: JourneysRepository?
    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let placesToVisitRepository: PlacesToVisitRepository?
    private let notesRepository: NotesRepository?
    private let logger: Logger

    init(databaseManager: DatabaseManager = .shared) {
        self.journeysRepository = databaseManager.journeysRepository
        self.transportsRepository = databaseManager.transportsRepository
        self.hotelsRepository = databaseManager.hotelsRepository
        self.carRentalsRepository = databaseManager.carRentalsRepository
        self.placesToVisitRepository = databaseManager.placesToVisitRepository
        self.notesRepository = databaseManager.notesRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "SearchService")
    }

    func search(query: String) -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lowercasedQuery = query.lowercased()
        var results: [SearchResult] = []

        // Build a journey name lookup for subtitles
        let allJourneys = journeysRepository?.fetchAll() ?? []
        let journeyNameMap = Dictionary(uniqueKeysWithValues: allJourneys.map { ($0.id, $0.name) })

        // Search journeys
        results.append(contentsOf: searchJourneys(query: lowercasedQuery))

        // Search transports
        results.append(contentsOf: searchTransports(query: lowercasedQuery, journeyNameMap: journeyNameMap))

        // Search hotels
        results.append(contentsOf: searchHotels(query: lowercasedQuery, journeyNameMap: journeyNameMap))

        // Search car rentals
        results.append(contentsOf: searchCarRentals(query: lowercasedQuery, journeyNameMap: journeyNameMap))

        // Search places to visit
        results.append(contentsOf: searchPlaces(query: lowercasedQuery, journeyNameMap: journeyNameMap))

        // Search notes
        results.append(contentsOf: searchNotes(query: lowercasedQuery, journeyNameMap: journeyNameMap))

        return results
    }

    private func searchJourneys(query: String) -> [SearchResult] {
        let journeys = journeysRepository?.fetchAll() ?? []

        return journeys.filter { journey in
            journey.name.lowercased().contains(query) ||
            journey.destination.lowercased().contains(query) ||
            (journey.notes?.lowercased().contains(query) ?? false)
        }.map { journey in
            SearchResult(
                id: journey.id,
                type: .journey,
                title: journey.name,
                subtitle: journey.destination,
                journeyId: journey.id,
                journeyName: journey.name
            )
        }
    }

    private func searchTransports(query: String, journeyNameMap: [UUID: String]) -> [SearchResult] {
        let transports = transportsRepository?.fetchAll() ?? []

        return transports.filter { transport in
            transport.departureLocation.lowercased().contains(query) ||
            transport.arrivalLocation.lowercased().contains(query) ||
            (transport.carrier?.lowercased().contains(query) ?? false) ||
            (transport.transportNumber?.lowercased().contains(query) ?? false) ||
            (transport.bookingReference?.lowercased().contains(query) ?? false)
        }.map { transport in
            SearchResult(
                id: transport.id,
                type: .transport,
                title: "\(transport.departureLocation) → \(transport.arrivalLocation)",
                subtitle: transport.carrier ?? transport.type.displayName,
                journeyId: transport.journeyId,
                journeyName: journeyNameMap[transport.journeyId]
            )
        }
    }

    private func searchHotels(query: String, journeyNameMap: [UUID: String]) -> [SearchResult] {
        let hotels = hotelsRepository?.fetchAll() ?? []

        return hotels.filter { hotel in
            hotel.name.lowercased().contains(query) ||
            hotel.address.lowercased().contains(query) ||
            (hotel.bookingReference?.lowercased().contains(query) ?? false)
        }.map { hotel in
            SearchResult(
                id: hotel.id,
                type: .hotel,
                title: hotel.name,
                subtitle: hotel.address,
                journeyId: hotel.journeyId,
                journeyName: journeyNameMap[hotel.journeyId]
            )
        }
    }

    private func searchCarRentals(query: String, journeyNameMap: [UUID: String]) -> [SearchResult] {
        let rentals = carRentalsRepository?.fetchAll() ?? []

        return rentals.filter { rental in
            rental.company.lowercased().contains(query) ||
            rental.pickupLocation.lowercased().contains(query) ||
            rental.dropoffLocation.lowercased().contains(query) ||
            (rental.bookingReference?.lowercased().contains(query) ?? false) ||
            (rental.carType?.lowercased().contains(query) ?? false)
        }.map { rental in
            SearchResult(
                id: rental.id,
                type: .carRental,
                title: rental.company,
                subtitle: rental.pickupLocation,
                journeyId: rental.journeyId,
                journeyName: journeyNameMap[rental.journeyId]
            )
        }
    }

    private func searchPlaces(query: String, journeyNameMap: [UUID: String]) -> [SearchResult] {
        let places = placesToVisitRepository?.fetchAll() ?? []

        return places.filter { place in
            place.name.lowercased().contains(query) ||
            (place.address?.lowercased().contains(query) ?? false) ||
            (place.notes?.lowercased().contains(query) ?? false)
        }.map { place in
            SearchResult(
                id: place.id,
                type: .place,
                title: place.name,
                subtitle: place.address,
                journeyId: place.journeyId,
                journeyName: journeyNameMap[place.journeyId]
            )
        }
    }

    private func searchNotes(query: String, journeyNameMap: [UUID: String]) -> [SearchResult] {
        let notes = notesRepository?.fetchAll() ?? []

        return notes.filter { note in
            note.title.lowercased().contains(query) ||
            note.content.lowercased().contains(query)
        }.map { note in
            SearchResult(
                id: note.id,
                type: .note,
                title: note.title,
                subtitle: note.contentPreview,
                journeyId: note.journeyId,
                journeyName: journeyNameMap[note.journeyId]
            )
        }
    }
}
