import Foundation
import Combine
import os

/// Represents a file to be shared, with optional custom name.
class ShareFileItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let originalName: String
    let fileExtension: String
    @Published var customName: String  // Optional custom display name (empty = use filename)

    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        self.fileExtension = url.pathExtension
        // Custom name starts empty - user can optionally fill it
        self.customName = ""
    }
}

/// ViewModel for the Share Extension.
/// Handles loading journeys, managing shared content, and saving entities.
@MainActor
class ShareViewModel: ObservableObject {
    // Content
    let contentType: SharedContentType
    @Published var files: [ShareFileItem] = []

    // For text-based content
    @Published var selectedEntityType: ShareEntityType = .note
    @Published var sharedText: String = ""
    @Published var sharedURL: URL?

    // Journey selection
    @Published var journeys: [Journey] = []
    @Published var selectedJourneyId: UUID?

    // UI state
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage: String?

    // Form data for text-based entities
    @Published var entityTitle: String = ""
    @Published var entityNotes: String = ""
    @Published var bookingReference: String = ""

    private let onComplete: (Bool) -> Void
    private let onCancel: () -> Void

    private let journeysRepository: JourneysRepository?
    private let documentsRepository: DocumentsRepository?
    private let notesRepository: NotesRepository?
    private let placesRepository: PlacesToVisitRepository?
    private let transportsRepository: TransportsRepository?
    private let hotelsRepository: HotelsRepository?
    private let carRentalsRepository: CarRentalsRepository?
    private let documentService: DocumentService
    private let logger = Logger(subsystem: "ShareExtension", category: "ShareViewModel")

    var canSave: Bool {
        selectedJourneyId != nil && !isSaving && !journeys.isEmpty
    }

    var isFileBased: Bool {
        if case .files = contentType {
            return true
        }
        return false
    }

    /// Convenience initializer for file-based sharing (backwards compatibility)
    convenience init(fileURLs: [URL], onComplete: @escaping (Bool) -> Void, onCancel: @escaping () -> Void) {
        self.init(contentType: .files(fileURLs), onComplete: onComplete, onCancel: onCancel)
    }

    init(contentType: SharedContentType, onComplete: @escaping (Bool) -> Void, onCancel: @escaping () -> Void) {
        self.contentType = contentType
        self.onComplete = onComplete
        self.onCancel = onCancel

        // Access shared database via DatabaseManager
        self.journeysRepository = DatabaseManager.shared.journeysRepository
        self.documentsRepository = DatabaseManager.shared.documentsRepository
        self.notesRepository = DatabaseManager.shared.notesRepository
        self.placesRepository = DatabaseManager.shared.placesToVisitRepository
        self.transportsRepository = DatabaseManager.shared.transportsRepository
        self.hotelsRepository = DatabaseManager.shared.hotelsRepository
        self.carRentalsRepository = DatabaseManager.shared.carRentalsRepository
        self.documentService = DocumentService.shared

        // Initialize based on content type
        switch contentType {
        case .files(let urls):
            self.files = urls.map { ShareFileItem(url: $0) }

        case .text(let text):
            self.sharedText = text
            self.selectedEntityType = ContentAnalyzer.suggestEntityType(for: text)
            self.entityTitle = ContentAnalyzer.extractFirstLine(from: text)
            self.entityNotes = text
            if let ref = ContentAnalyzer.extractBookingReference(from: text) {
                self.bookingReference = ref
            }

        case .url(let url, let title):
            self.sharedURL = url
            self.sharedText = url.absoluteString
            self.selectedEntityType = ContentAnalyzer.suggestEntityType(for: url.absoluteString)
            self.entityTitle = title ?? url.host ?? ""
            self.entityNotes = url.absoluteString

        case .urlWithText(let url, let text):
            self.sharedURL = url
            self.sharedText = text
            self.selectedEntityType = ContentAnalyzer.suggestEntityType(for: text)
            self.entityTitle = ContentAnalyzer.extractFirstLine(from: text)
            self.entityNotes = "\(text)\n\n\(url.absoluteString)"
            if let ref = ContentAnalyzer.extractBookingReference(from: text) {
                self.bookingReference = ref
            }
        }

        // Load journeys
        loadJourneys()
    }

    private func loadJourneys() {
        isLoading = true
        errorMessage = nil

        guard let repository = journeysRepository else {
            errorMessage = L("share.error.database")
            isLoading = false
            return
        }

        let allJourneys = repository.fetchAll()

        // Sort: active first, then upcoming by start date, then past by end date (recent first)
        let now = Date()
        journeys = allJourneys.sorted { j1, j2 in
            let j1Active = j1.isActive
            let j2Active = j2.isActive
            let j1Upcoming = j1.startDate > now
            let j2Upcoming = j2.startDate > now

            // Active journeys first
            if j1Active && !j2Active { return true }
            if !j1Active && j2Active { return false }

            // Then upcoming journeys (sorted by start date, soonest first)
            if j1Upcoming && j2Upcoming { return j1.startDate < j2.startDate }
            if j1Upcoming && !j2Upcoming { return true }
            if !j1Upcoming && j2Upcoming { return false }

            // Then past journeys (sorted by end date, most recent first)
            return j1.endDate > j2.endDate
        }

        // Pre-select first active journey, or first upcoming, or first in list
        selectedJourneyId = journeys.first(where: { $0.isActive })?.id
            ?? journeys.first(where: { $0.startDate > now })?.id
            ?? journeys.first?.id

        isLoading = false
        logger.info("Loaded \(allJourneys.count) journeys")
    }

    func save() {
        guard let journeyId = selectedJourneyId else {
            errorMessage = L("share.error.no_journey")
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            var success: Bool

            switch contentType {
            case .files:
                success = await saveFiles(journeyId: journeyId)
            case .text, .url, .urlWithText:
                success = await saveTextEntity(journeyId: journeyId)
            }

            isSaving = false

            if success {
                onComplete(true)
            } else {
                errorMessage = L("share.error.save_failed")
            }
        }
    }

    private func saveFiles(journeyId: UUID) async -> Bool {
        var allSucceeded = true

        for file in files {
            do {
                // Save file to shared documents directory
                guard let result = documentService.saveDocument(from: file.url, journeyId: journeyId) else {
                    throw NSError(domain: "ShareExtension", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save file"])
                }

                // Determine document type from extension
                let docType = DocumentType.fromExtension(file.fileExtension)

                // Create database record
                // name is optional - only set if user provided a custom name
                let customName: String? = file.customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : file.customName.trimmingCharacters(in: .whitespacesAndNewlines)

                let document = Document(
                    id: UUID(),
                    journeyId: journeyId,
                    name: customName,
                    fileType: docType,
                    fileName: result.fileName,
                    filePath: nil,
                    fileSize: result.fileSize,
                    notes: nil,
                    createdAt: Date()
                )

                let success = documentsRepository?.insert(document) ?? false
                if !success {
                    logger.error("Failed to insert document record for: \(file.originalName)")
                    allSucceeded = false
                } else {
                    logger.info("Saved document: \(file.originalName) to journey: \(journeyId)")
                }

                // Clean up temp file
                try? FileManager.default.removeItem(at: file.url)

            } catch {
                logger.error("Failed to save document: \(error.localizedDescription)")
                allSucceeded = false
            }
        }

        return allSucceeded
    }

    private func saveTextEntity(journeyId: UUID) async -> Bool {
        switch selectedEntityType {
        case .note:
            return saveNote(journeyId: journeyId)
        case .place:
            return savePlace(journeyId: journeyId)
        case .transport:
            return saveTransport(journeyId: journeyId)
        case .hotel:
            return saveHotel(journeyId: journeyId)
        case .carRental:
            return saveCarRental(journeyId: journeyId)
        }
    }

    private func saveNote(journeyId: UUID) -> Bool {
        let note = Note(
            id: UUID(),
            journeyId: journeyId,
            title: entityTitle.isEmpty ? L("share.entity_type.note") : entityTitle,
            content: entityNotes,
            createdAt: Date()
        )

        let success = notesRepository?.insert(note) ?? false
        if success {
            logger.info("Saved note to journey: \(journeyId)")
        }
        return success
    }

    private func savePlace(journeyId: UUID) -> Bool {
        // Determine URL and notes based on content type
        let urlToSave: String?
        let notesToSave: String?

        switch contentType {
        case .url(let url, _):
            urlToSave = url.absoluteString
            notesToSave = nil
        case .urlWithText(let url, let text):
            urlToSave = url.absoluteString
            notesToSave = text.isEmpty ? nil : text
        case .text:
            urlToSave = sharedURL?.absoluteString
            notesToSave = entityNotes.isEmpty ? nil : entityNotes
        default:
            urlToSave = nil
            notesToSave = entityNotes.isEmpty ? nil : entityNotes
        }

        let place = PlaceToVisit(
            id: UUID(),
            journeyId: journeyId,
            name: entityTitle.isEmpty ? L("share.entity_type.place") : entityTitle,
            category: .other,
            isVisited: false,
            url: urlToSave,
            notes: notesToSave,
            createdAt: Date()
        )

        let success = placesRepository?.insert(place) ?? false
        if success {
            logger.info("Saved place to journey: \(journeyId)")
        }
        return success
    }

    private func saveTransport(journeyId: UUID) -> Bool {
        let transport = Transport(
            id: UUID(),
            journeyId: journeyId,
            type: .flight,
            departureLocation: "",
            arrivalLocation: "",
            departureDate: Date(),
            arrivalDate: Date(),
            bookingReference: bookingReference.isEmpty ? nil : bookingReference,
            notes: entityNotes.isEmpty ? nil : entityNotes,
            createdAt: Date()
        )

        let success = transportsRepository?.insert(transport) ?? false
        if success {
            logger.info("Saved transport to journey: \(journeyId)")
        }
        return success
    }

    private func saveHotel(journeyId: UUID) -> Bool {
        let hotel = Hotel(
            id: UUID(),
            journeyId: journeyId,
            name: entityTitle.isEmpty ? L("share.entity_type.hotel") : entityTitle,
            address: "",
            checkInDate: Date(),
            checkOutDate: Date().addingTimeInterval(86400), // +1 day
            bookingReference: bookingReference.isEmpty ? nil : bookingReference,
            notes: entityNotes.isEmpty ? nil : entityNotes,
            createdAt: Date()
        )

        let success = hotelsRepository?.insert(hotel) ?? false
        if success {
            logger.info("Saved hotel to journey: \(journeyId)")
        }
        return success
    }

    private func saveCarRental(journeyId: UUID) -> Bool {
        let carRental = CarRental(
            id: UUID(),
            journeyId: journeyId,
            company: entityTitle.isEmpty ? nil : entityTitle,
            pickupDate: Date(),
            dropoffDate: Date().addingTimeInterval(86400), // +1 day
            bookingReference: bookingReference.isEmpty ? nil : bookingReference,
            carType: L("share.entity_type.car_rental"),
            notes: entityNotes.isEmpty ? nil : entityNotes,
            createdAt: Date()
        )

        let success = carRentalsRepository?.insert(carRental) ?? false
        if success {
            logger.info("Saved car rental to journey: \(journeyId)")
        }
        return success
    }

    func cancel() {
        // Clean up temp files
        if case .files = contentType {
            for file in files {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
        onCancel()
    }
}
