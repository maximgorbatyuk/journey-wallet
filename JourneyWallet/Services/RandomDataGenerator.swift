import Foundation
import os

/// Service for generating random test data for journeys (Developer mode only)
class RandomDataGenerator {

    private let db: DatabaseManager
    private let logger: Logger

    init(db: DatabaseManager = .shared) {
        self.db = db
        self.logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet", category: "RandomDataGenerator")
    }

    // MARK: - Main Generation Method

    func generateRandomData(for journey: Journey) {
        logger.info("Starting random data generation for journey: \(journey.name)")

        // Step 1: Delete all existing data for this journey
        deleteExistingData(for: journey.id)

        // Step 2: Generate new random data
        let isOddSecond = Int(Date().timeIntervalSince1970) % 2 == 1
        let flightCount = isOddSecond ? 4 : 2

        // Generate flights (first departure and last arrival match journey dates)
        let flights = generateFlights(for: journey, count: flightCount)
        flights.forEach { _ = db.transportsRepository?.insert($0) }

        // Generate airport transfers (1-2)
        let transfers = generateTransfers(for: journey, flights: flights)
        transfers.forEach { _ = db.transportsRepository?.insert($0) }

        // Generate hotels (1-2, dates match journey)
        let hotels = generateHotels(for: journey)
        hotels.forEach { _ = db.hotelsRepository?.insert($0) }

        // Generate train/bus transport (2-3)
        let groundTransport = generateGroundTransport(for: journey)
        groundTransport.forEach { _ = db.transportsRepository?.insert($0) }

        // Generate car rentals (1-2)
        let carRentals = generateCarRentals(for: journey)
        carRentals.forEach { _ = db.carRentalsRepository?.insert($0) }

        // Generate notes (3-4)
        let notes = generateNotes(for: journey)
        notes.forEach { _ = db.notesRepository?.insert($0) }

        // Generate places to visit (8-15)
        let places = generatePlaces(for: journey)
        places.forEach { _ = db.placesToVisitRepository?.insert($0) }

        // Generate expenses for transport, hotels, car rentals
        let expenses = generateExpenses(for: journey, flights: flights, transfers: transfers, groundTransport: groundTransport, hotels: hotels, carRentals: carRentals)
        expenses.forEach { _ = db.expensesRepository?.insert($0) }

        logger.info("Random data generation completed for journey: \(journey.name)")
    }

    // MARK: - Delete Existing Data

    private func deleteExistingData(for journeyId: UUID) {
        logger.debug("Deleting existing data for journey: \(journeyId)")

        // Delete all related data
        _ = db.transportsRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.hotelsRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.carRentalsRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.notesRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.placesToVisitRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.remindersRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.expensesRepository?.deleteByJourneyId(journeyId: journeyId)
        _ = db.documentsRepository?.deleteByJourneyId(journeyId: journeyId)

        logger.debug("Existing data deleted for journey: \(journeyId)")
    }

    // MARK: - Flights Generation

    private func generateFlights(for journey: Journey, count: Int) -> [Transport] {
        var flights: [Transport] = []

        let airlines = ["Lufthansa", "Air France", "British Airways", "Emirates", "Qatar Airways", "Turkish Airlines", "KLM", "Swiss"]
        let airports = ["JFK", "LAX", "LHR", "CDG", "FRA", "DXB", "SIN", "HND", "AMS", "IST", "MAD", "FCO"]

        // First flight: starts at journey start date, departure from home airport
        let homeAirport = airports.randomElement()!
        var currentAirport = homeAirport
        var currentDate = journey.startDate

        for i in 0..<count {
            let isLastFlight = i == count - 1
            let destinationAirport = isLastFlight ? homeAirport : airports.filter { $0 != currentAirport }.randomElement()!

            // Calculate departure time (morning/afternoon)
            let departureHour = Int.random(in: 6...18)
            var departureDate = Calendar.current.date(bySettingHour: departureHour, minute: Int.random(in: 0...59), second: 0, of: currentDate)!

            // For last flight, set it to journey end date
            if isLastFlight {
                departureDate = Calendar.current.date(bySettingHour: departureHour, minute: Int.random(in: 0...59), second: 0, of: journey.endDate)!
            }

            // Flight duration: 2-12 hours
            let flightDurationHours = Double.random(in: 2...12)
            let arrivalDate = departureDate.addingTimeInterval(flightDurationHours * 3600)

            let airline = airlines.randomElement()!
            let flightNumber = "\(airline.prefix(2).uppercased())\(Int.random(in: 100...9999))"

            let flight = Transport(
                journeyId: journey.id,
                type: .flight,
                carrier: airline,
                transportNumber: flightNumber,
                departureLocation: currentAirport,
                arrivalLocation: destinationAirport,
                departureDate: departureDate,
                arrivalDate: arrivalDate,
                bookingReference: generateBookingReference(),
                seatNumber: "\(Int.random(in: 1...35))\(["A", "B", "C", "D", "E", "F"].randomElement()!)",
                platform: "Terminal \(Int.random(in: 1...5))"
            )

            flights.append(flight)

            currentAirport = destinationAirport
            // Next flight is 1-3 days later
            currentDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 1...3), to: departureDate)!
        }

        return flights
    }

    // MARK: - Transfers Generation

    private func generateTransfers(for journey: Journey, flights: [Transport]) -> [Transport] {
        var transfers: [Transport] = []
        let transferCount = Int.random(in: 1...2)
        let providers = ["Uber", "Bolt", "Local Taxi", "Airport Shuttle", "Private Transfer", "Lyft"]
        let vehicles = ["Sedan", "SUV", "Van", "Minibus"]

        for i in 0..<min(transferCount, flights.count) {
            let flight = flights[i]

            // Transfer from airport to city center (30 min after flight arrival)
            let transferStart = flight.arrivalDate.addingTimeInterval(30 * 60)
            let transferEnd = transferStart.addingTimeInterval(Double.random(in: 30...90) * 60)

            let transfer = Transport(
                journeyId: journey.id,
                type: .transfer,
                carrier: providers.randomElement()!,
                transportNumber: vehicles.randomElement()!,
                departureLocation: "\(flight.arrivalLocation) Airport",
                arrivalLocation: "City Center",
                departureDate: transferStart,
                arrivalDate: transferEnd,
                bookingReference: generateBookingReference()
            )

            transfers.append(transfer)
        }

        return transfers
    }

    // MARK: - Ground Transport Generation (Train/Bus)

    private func generateGroundTransport(for journey: Journey) -> [Transport] {
        var transports: [Transport] = []
        let count = Int.random(in: 2...3)

        let trainCompanies = ["Deutsche Bahn", "SNCF", "Trenitalia", "Renfe", "Eurostar", "Thalys"]
        let busCompanies = ["FlixBus", "Greyhound", "National Express", "Megabus", "Eurolines"]
        let cities = ["Berlin", "Paris", "Rome", "Madrid", "Amsterdam", "Vienna", "Prague", "Barcelona", "Munich", "Milan"]

        let journeyDays = Calendar.current.dateComponents([.day], from: journey.startDate, to: journey.endDate).day ?? 7

        for i in 0..<count {
            let isTravel = Bool.random()
            let type: TransportType = isTravel ? .train : .bus
            let company = isTravel ? trainCompanies.randomElement()! : busCompanies.randomElement()!

            // Random day during journey
            let dayOffset = Int.random(in: 1..<max(2, journeyDays))
            let travelDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: journey.startDate)!
            let departureHour = Int.random(in: 7...20)
            let departureDate = Calendar.current.date(bySettingHour: departureHour, minute: Int.random(in: 0...59), second: 0, of: travelDate)!

            // Duration: 1-5 hours
            let durationHours = Double.random(in: 1...5)
            let arrivalDate = departureDate.addingTimeInterval(durationHours * 3600)

            let fromCity = cities.randomElement()!
            let toCity = cities.filter { $0 != fromCity }.randomElement()!

            let transport = Transport(
                journeyId: journey.id,
                type: type,
                carrier: company,
                transportNumber: isTravel ? "ICE \(Int.random(in: 100...999))" : "Route \(Int.random(in: 1...50))",
                departureLocation: "\(fromCity) \(isTravel ? "Hauptbahnhof" : "Bus Station")",
                arrivalLocation: "\(toCity) \(isTravel ? "Central" : "Bus Terminal")",
                departureDate: departureDate,
                arrivalDate: arrivalDate,
                bookingReference: generateBookingReference(),
                seatNumber: "\(Int.random(in: 1...99))",
                platform: isTravel ? "Platform \(Int.random(in: 1...15))" : "Gate \(Int.random(in: 1...10))"
            )

            transports.append(transport)
        }

        return transports
    }

    // MARK: - Hotels Generation

    private func generateHotels(for journey: Journey) -> [Hotel] {
        var hotels: [Hotel] = []
        let hotelCount = Int.random(in: 1...2)

        let hotelNames = [
            "Grand Hotel", "Marriott", "Hilton", "Hyatt Regency", "Four Seasons",
            "InterContinental", "Radisson Blu", "Sheraton", "Westin", "Novotel",
            "Holiday Inn", "Best Western", "Mercure", "Ibis", "Premier Inn"
        ]
        let roomTypes = ["Standard Room", "Deluxe Room", "Suite", "Executive Room", "Family Room", "Superior Room"]
        let cities = ["Downtown", "City Center", "Old Town", "Business District", "Waterfront"]

        if hotelCount == 1 {
            // Single hotel for entire journey
            let hotel = Hotel(
                journeyId: journey.id,
                name: hotelNames.randomElement()!,
                address: "\(Int.random(in: 1...200)) \(cities.randomElement()!) Street",
                checkInDate: journey.startDate,
                checkOutDate: journey.endDate,
                bookingReference: generateBookingReference(),
                roomType: roomTypes.randomElement()!,
                contactPhone: "+\(Int.random(in: 1...99)) \(Int.random(in: 100...999)) \(Int.random(in: 1000...9999))"
            )
            hotels.append(hotel)
        } else {
            // Two hotels, split the journey
            let midPoint = Calendar.current.date(
                byAdding: .day,
                value: (Calendar.current.dateComponents([.day], from: journey.startDate, to: journey.endDate).day ?? 7) / 2,
                to: journey.startDate
            )!

            let hotel1 = Hotel(
                journeyId: journey.id,
                name: hotelNames.randomElement()!,
                address: "\(Int.random(in: 1...200)) \(cities.randomElement()!) Street",
                checkInDate: journey.startDate,
                checkOutDate: midPoint,
                bookingReference: generateBookingReference(),
                roomType: roomTypes.randomElement()!,
                contactPhone: "+\(Int.random(in: 1...99)) \(Int.random(in: 100...999)) \(Int.random(in: 1000...9999))"
            )
            hotels.append(hotel1)

            let hotel2 = Hotel(
                journeyId: journey.id,
                name: hotelNames.filter { $0 != hotel1.name }.randomElement()!,
                address: "\(Int.random(in: 1...200)) \(cities.randomElement()!) Avenue",
                checkInDate: midPoint,
                checkOutDate: journey.endDate,
                bookingReference: generateBookingReference(),
                roomType: roomTypes.randomElement()!,
                contactPhone: "+\(Int.random(in: 1...99)) \(Int.random(in: 100...999)) \(Int.random(in: 1000...9999))"
            )
            hotels.append(hotel2)
        }

        return hotels
    }

    // MARK: - Car Rentals Generation

    private func generateCarRentals(for journey: Journey) -> [CarRental] {
        var rentals: [CarRental] = []
        let count = Int.random(in: 1...2)

        let companies = ["Hertz", "Avis", "Enterprise", "Budget", "Sixt", "Europcar", "National", "Alamo"]
        let carTypes = ["Economy", "Compact", "Midsize", "SUV", "Luxury", "Convertible", "Minivan"]
        let locations = ["Airport", "Downtown Office", "Train Station", "City Center"]

        let journeyDays = Calendar.current.dateComponents([.day], from: journey.startDate, to: journey.endDate).day ?? 7

        for _ in 0..<count {
            let startDay = Int.random(in: 0..<max(1, journeyDays - 2))
            let rentalDays = Int.random(in: 1...min(3, journeyDays - startDay))

            let pickupDate = Calendar.current.date(byAdding: .day, value: startDay, to: journey.startDate)!
            let dropoffDate = Calendar.current.date(byAdding: .day, value: rentalDays, to: pickupDate)!

            let pickupLocation = locations.randomElement()!
            let isSameLocation = Bool.random()

            let rental = CarRental(
                journeyId: journey.id,
                company: companies.randomElement()!,
                pickupLocation: pickupLocation,
                dropoffLocation: isSameLocation ? pickupLocation : locations.filter { $0 != pickupLocation }.randomElement()!,
                pickupDate: pickupDate,
                dropoffDate: dropoffDate,
                bookingReference: generateBookingReference(),
                carType: carTypes.randomElement()!
            )

            rentals.append(rental)
        }

        return rentals
    }

    // MARK: - Notes Generation

    private func generateNotes(for journey: Journey) -> [Note] {
        let noteTitlesAndContent: [(String, String)] = [
            ("Packing List", "- Passport and travel documents\n- Phone charger and adapter\n- Comfortable walking shoes\n- Weather-appropriate clothing\n- Toiletries\n- Camera\n- Medications"),
            ("Emergency Contacts", "Embassy: +1-234-567-8900\nLocal Police: 112\nHotel Reception: Ext. 0\nTravel Insurance: 1-800-XXX-XXXX"),
            ("Restaurant Recommendations", "1. La Trattoria - Italian cuisine, great pasta\n2. The Golden Dragon - Best dim sum in town\n3. Cafe Central - Perfect for breakfast\n4. Le Petit Bistro - Romantic dinner spot"),
            ("Day Trip Ideas", "- Mountain hiking trail (2 hours from city)\n- Historic castle tour\n- Wine tasting in the countryside\n- Beach day at the coast"),
            ("Budget Notes", "Daily budget: $150\n- Accommodation: $80\n- Food: $40\n- Activities: $30\nEmergency fund: $200"),
            ("Local Tips", "- Tip 10-15% at restaurants\n- Public transport is efficient\n- Most shops close on Sundays\n- Learn basic phrases in local language"),
            ("Must-See Attractions", "1. Old Town Square\n2. National Museum\n3. Cathedral\n4. Botanical Gardens\n5. River cruise")
        ]

        let count = Int.random(in: 3...4)
        var notes: [Note] = []
        var usedIndices: Set<Int> = []

        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int.random(in: 0..<noteTitlesAndContent.count)
            } while usedIndices.contains(index)
            usedIndices.insert(index)

            let (title, content) = noteTitlesAndContent[index]

            let note = Note(
                journeyId: journey.id,
                title: title,
                content: content
            )
            notes.append(note)
        }

        return notes
    }

    // MARK: - Places to Visit Generation

    private func generatePlaces(for journey: Journey) -> [PlaceToVisit] {
        var places: [PlaceToVisit] = []
        let count = Int.random(in: 8...15)

        let placeData: [(String, PlaceCategory, String?, String?)] = [
            // Restaurants with addresses
            ("La Bella Italia", .restaurant, "123 Main Street, Downtown", nil),
            ("Sakura Sushi", .restaurant, "45 Cherry Blossom Lane", nil),
            ("The Golden Spoon", .restaurant, nil, "https://maps.google.com/?q=golden+spoon+restaurant"),
            ("Cafe Mozart", .restaurant, "78 Vienna Street", nil),

            // Attractions with Google Maps links
            ("Eiffel Tower", .attraction, nil, "https://maps.google.com/?q=eiffel+tower+paris"),
            ("Central Park", .attraction, nil, "https://maps.google.com/?q=central+park+new+york"),
            ("Big Ben", .attraction, "Westminster, London", nil),
            ("Colosseum", .attraction, nil, "https://maps.google.com/?q=colosseum+rome"),

            // Museums
            ("National Art Museum", .museum, "1 Museum Plaza", nil),
            ("History Museum", .museum, nil, "https://maps.google.com/?q=history+museum"),
            ("Science Center", .museum, "500 Discovery Drive", nil),

            // Shopping
            ("Grand Bazaar", .shopping, nil, "https://maps.google.com/?q=grand+bazaar"),
            ("Fashion District", .shopping, "Shopping Street 10-50", nil),
            ("Local Market", .shopping, "Market Square", nil),
            ("Outlet Mall", .shopping, nil, "https://maps.google.com/?q=outlet+mall"),

            // Nature
            ("Botanical Gardens", .nature, "Green Park Road", nil),
            ("Mountain Viewpoint", .nature, nil, "https://maps.google.com/?q=mountain+viewpoint"),
            ("Lake Park", .nature, "Lakeside Drive 1", nil),
            ("Sunset Beach", .nature, nil, "https://maps.google.com/?q=sunset+beach"),

            // Entertainment
            ("Opera House", .entertainment, "1 Opera Square", nil),
            ("Jazz Club Blue Note", .entertainment, nil, "https://maps.google.com/?q=blue+note+jazz"),
            ("Cinema City", .entertainment, "Entertainment Boulevard 25", nil),
            ("Comedy Club", .entertainment, "42 Laugh Lane", nil)
        ]

        let journeyDays = Calendar.current.dateComponents([.day], from: journey.startDate, to: journey.endDate).day ?? 7
        var usedIndices: Set<Int> = []

        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int.random(in: 0..<placeData.count)
            } while usedIndices.contains(index) && usedIndices.count < placeData.count

            if usedIndices.count >= placeData.count {
                break
            }
            usedIndices.insert(index)

            let (name, category, address, mapLink) = placeData[index]

            // Random planned date within journey
            let hasPlannedDate = Bool.random()
            var plannedDate: Date? = nil
            if hasPlannedDate {
                let dayOffset = Int.random(in: 0...journeyDays)
                plannedDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: journey.startDate)
            }

            let place = PlaceToVisit(
                journeyId: journey.id,
                name: name,
                address: mapLink ?? address,
                category: category,
                isVisited: Bool.random() && Bool.random(), // ~25% chance of being visited
                plannedDate: plannedDate
            )
            places.append(place)
        }

        return places
    }

    // MARK: - Expenses Generation

    private func generateExpenses(
        for journey: Journey,
        flights: [Transport],
        transfers: [Transport],
        groundTransport: [Transport],
        hotels: [Hotel],
        carRentals: [CarRental]
    ) -> [Expense] {
        var expenses: [Expense] = []
        let currencies: [Currency] = [.usd, .eur, .gbp]

        // Expenses for flights
        for flight in flights {
            let expense = Expense(
                journeyId: journey.id,
                title: "\(flight.carrier ?? "Flight") \(flight.transportNumber ?? "")",
                amount: Decimal(Int.random(in: 150...800)),
                currency: currencies.randomElement()!,
                category: .transport,
                date: flight.departureDate
            )
            expenses.append(expense)
        }

        // Expenses for transfers
        for transfer in transfers {
            let expense = Expense(
                journeyId: journey.id,
                title: "\(transfer.carrier ?? "Transfer"): \(transfer.departureLocation) → \(transfer.arrivalLocation)",
                amount: Decimal(Int.random(in: 20...80)),
                currency: currencies.randomElement()!,
                category: .transport,
                date: transfer.departureDate
            )
            expenses.append(expense)
        }

        // Expenses for ground transport
        for transport in groundTransport {
            let expense = Expense(
                journeyId: journey.id,
                title: "\(transport.type.displayName): \(transport.carrier ?? "")",
                amount: Decimal(Int.random(in: 30...150)),
                currency: currencies.randomElement()!,
                category: .transport,
                date: transport.departureDate
            )
            expenses.append(expense)
        }

        // Expenses for hotels
        for hotel in hotels {
            let nights = max(1, hotel.nightsCount)
            let expense = Expense(
                journeyId: journey.id,
                title: "\(hotel.name) (\(nights) nights)",
                amount: Decimal(Int.random(in: 80...250) * nights),
                currency: currencies.randomElement()!,
                category: .accommodation,
                date: hotel.checkInDate
            )
            expenses.append(expense)
        }

        // Expenses for car rentals
        for rental in carRentals {
            let days = max(1, rental.rentalDays)
            let expense = Expense(
                journeyId: journey.id,
                title: "\(rental.company) - \(rental.carType ?? "Car") (\(days) days)",
                amount: Decimal(Int.random(in: 40...120) * days),
                currency: currencies.randomElement()!,
                category: .transport,
                date: rental.pickupDate
            )
            expenses.append(expense)
        }

        return expenses
    }

    // MARK: - Helpers

    private func generateBookingReference() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let digits = "0123456789"

        var reference = ""
        for _ in 0..<3 {
            reference.append(letters.randomElement()!)
        }
        for _ in 0..<4 {
            reference.append(digits.randomElement()!)
        }
        return reference
    }
}
