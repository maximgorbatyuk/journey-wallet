import Foundation
import SQLite
import os

class Migration_20260118_JourneyTables {

    private let migrationName = "20260118_JourneyTables"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(subsystem: "dev.mgorbatyuk.journeywallet.migrations", category: migrationName)

        do {
            try createJourneysTable(logger: logger)
            try createTransportsTable(logger: logger)
            try createHotelsTable(logger: logger)
            try createCarRentalsTable(logger: logger)
            try createDocumentsTable(logger: logger)
            try createNotesTable(logger: logger)
            try createPlacesToVisitTable(logger: logger)
            try createRemindersTable(logger: logger)
            try createExpensesTable(logger: logger)

            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    private func createJourneysTable(logger: Logger) throws {
        let table = Table("journeys")

        let id = Expression<String>("id")
        let name = Expression<String>("name")
        let destination = Expression<String>("destination")
        let startDate = Expression<Date>("start_date")
        let endDate = Expression<Date>("end_date")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(destination)
            t.column(startDate)
            t.column(endDate)
            t.column(notes)
            t.column(createdAt)
            t.column(updatedAt)
        })

        logger.debug("Journeys table created successfully")
    }

    private func createTransportsTable(logger: Logger) throws {
        let table = Table("transports")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let type = Expression<String>("type")
        let carrier = Expression<String?>("carrier")
        let transportNumber = Expression<String?>("transport_number")
        let departureLocation = Expression<String>("departure_location")
        let arrivalLocation = Expression<String>("arrival_location")
        let departureDate = Expression<Date>("departure_date")
        let arrivalDate = Expression<Date>("arrival_date")
        let bookingReference = Expression<String?>("booking_reference")
        let seatNumber = Expression<String?>("seat_number")
        let platform = Expression<String?>("platform")
        let cost = Expression<String?>("cost")
        let currency = Expression<String?>("currency")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(type)
            t.column(carrier)
            t.column(transportNumber)
            t.column(departureLocation)
            t.column(arrivalLocation)
            t.column(departureDate)
            t.column(arrivalDate)
            t.column(bookingReference)
            t.column(seatNumber)
            t.column(platform)
            t.column(cost)
            t.column(currency)
            t.column(notes)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Transports table created successfully")
    }

    private func createHotelsTable(logger: Logger) throws {
        let table = Table("hotels")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let name = Expression<String>("name")
        let address = Expression<String>("address")
        let checkInDate = Expression<Date>("check_in_date")
        let checkOutDate = Expression<Date>("check_out_date")
        let bookingReference = Expression<String?>("booking_reference")
        let roomType = Expression<String?>("room_type")
        let cost = Expression<String?>("cost")
        let currency = Expression<String?>("currency")
        let contactPhone = Expression<String?>("contact_phone")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(name)
            t.column(address)
            t.column(checkInDate)
            t.column(checkOutDate)
            t.column(bookingReference)
            t.column(roomType)
            t.column(cost)
            t.column(currency)
            t.column(contactPhone)
            t.column(notes)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Hotels table created successfully")
    }

    private func createCarRentalsTable(logger: Logger) throws {
        let table = Table("car_rentals")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let company = Expression<String>("company")
        let pickupLocation = Expression<String>("pickup_location")
        let dropoffLocation = Expression<String>("dropoff_location")
        let pickupDate = Expression<Date>("pickup_date")
        let dropoffDate = Expression<Date>("dropoff_date")
        let bookingReference = Expression<String?>("booking_reference")
        let carType = Expression<String?>("car_type")
        let cost = Expression<String?>("cost")
        let currency = Expression<String?>("currency")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(company)
            t.column(pickupLocation)
            t.column(dropoffLocation)
            t.column(pickupDate)
            t.column(dropoffDate)
            t.column(bookingReference)
            t.column(carType)
            t.column(cost)
            t.column(currency)
            t.column(notes)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Car rentals table created successfully")
    }

    private func createDocumentsTable(logger: Logger) throws {
        let table = Table("documents")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let name = Expression<String>("name")
        let fileType = Expression<String>("file_type")
        let fileName = Expression<String>("file_name")
        let fileSize = Expression<Int64>("file_size")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(name)
            t.column(fileType)
            t.column(fileName)
            t.column(fileSize)
            t.column(notes)
            t.column(createdAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Documents table created successfully")
    }

    private func createNotesTable(logger: Logger) throws {
        let table = Table("notes")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let title = Expression<String>("title")
        let content = Expression<String>("content")
        let createdAt = Expression<Date>("created_at")
        let updatedAt = Expression<Date>("updated_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(title)
            t.column(content)
            t.column(createdAt)
            t.column(updatedAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Notes table created successfully")
    }

    private func createPlacesToVisitTable(logger: Logger) throws {
        let table = Table("places_to_visit")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let name = Expression<String>("name")
        let address = Expression<String?>("address")
        let category = Expression<String>("category")
        let isVisited = Expression<Bool>("is_visited")
        let plannedDate = Expression<Date?>("planned_date")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(name)
            t.column(address)
            t.column(category)
            t.column(isVisited, defaultValue: false)
            t.column(plannedDate)
            t.column(notes)
            t.column(createdAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Places to visit table created successfully")
    }

    private func createRemindersTable(logger: Logger) throws {
        let table = Table("reminders")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let title = Expression<String>("title")
        let reminderDate = Expression<Date>("reminder_date")
        let isCompleted = Expression<Bool>("is_completed")
        let relatedEntityType = Expression<String?>("related_entity_type")
        let relatedEntityId = Expression<String?>("related_entity_id")
        let notificationId = Expression<String?>("notification_id")
        let createdAt = Expression<Date>("created_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(title)
            t.column(reminderDate)
            t.column(isCompleted, defaultValue: false)
            t.column(relatedEntityType)
            t.column(relatedEntityId)
            t.column(notificationId)
            t.column(createdAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))
        try db.run(table.createIndex(reminderDate, ifNotExists: true))

        logger.debug("Reminders table created successfully")
    }

    private func createExpensesTable(logger: Logger) throws {
        let table = Table("expenses")

        let id = Expression<String>("id")
        let journeyId = Expression<String>("journey_id")
        let title = Expression<String>("title")
        let amount = Expression<String>("amount")
        let currency = Expression<String>("currency")
        let category = Expression<String>("category")
        let date = Expression<Date>("date")
        let notes = Expression<String?>("notes")
        let createdAt = Expression<Date>("created_at")

        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(journeyId)
            t.column(title)
            t.column(amount)
            t.column(currency)
            t.column(category)
            t.column(date)
            t.column(notes)
            t.column(createdAt)
        })

        try db.run(table.createIndex(journeyId, ifNotExists: true))

        logger.debug("Expenses table created successfully")
    }
}
