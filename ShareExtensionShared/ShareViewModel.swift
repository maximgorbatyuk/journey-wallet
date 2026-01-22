import Foundation
import Combine
import os

/// Represents a file to be shared, with editable display name.
class ShareFileItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let originalName: String
    let fileExtension: String
    @Published var displayName: String

    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        self.fileExtension = url.pathExtension
        // Default display name is filename without extension
        self.displayName = url.deletingPathExtension().lastPathComponent
    }
}

/// ViewModel for the Share Extension.
/// Handles loading journeys, managing file state, and saving documents.
@MainActor
class ShareViewModel: ObservableObject {
    @Published var files: [ShareFileItem] = []
    @Published var journeys: [Journey] = []
    @Published var selectedJourneyId: UUID?
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let onComplete: (Bool) -> Void
    private let onCancel: () -> Void

    private let journeysRepository: JourneysRepository?
    private let documentsRepository: DocumentsRepository?
    private let documentService: DocumentService
    private let logger = Logger(subsystem: "ShareExtension", category: "ShareViewModel")

    var canSave: Bool {
        selectedJourneyId != nil && !files.isEmpty && !isSaving && !journeys.isEmpty
    }

    init(fileURLs: [URL], onComplete: @escaping (Bool) -> Void, onCancel: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onCancel = onCancel

        // Access shared database via DatabaseManager
        self.journeysRepository = DatabaseManager.shared.journeysRepository
        self.documentsRepository = DatabaseManager.shared.documentsRepository
        self.documentService = DocumentService.shared

        // Create file items
        self.files = fileURLs.map { ShareFileItem(url: $0) }

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
                    let document = Document(
                        id: UUID(),
                        journeyId: journeyId,
                        name: file.displayName.isEmpty ? file.originalName : file.displayName,
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
                        logger.info("Saved document: \(file.displayName) to journey: \(journeyId)")
                    }

                    // Clean up temp file
                    try? FileManager.default.removeItem(at: file.url)

                } catch {
                    logger.error("Failed to save document: \(error.localizedDescription)")
                    allSucceeded = false
                }
            }

            isSaving = false

            if allSucceeded {
                onComplete(true)
            } else {
                errorMessage = L("share.error.save_failed")
            }
        }
    }

    func cancel() {
        // Clean up temp files
        for file in files {
            try? FileManager.default.removeItem(at: file.url)
        }
        onCancel()
    }
}
