import Foundation
import os

@MainActor
@Observable
class NoteListViewModel {

    // MARK: - Properties

    var notes: [Note] = []
    var isLoading: Bool = false

    var showAddNoteSheet: Bool = false
    var noteToEdit: Note? = nil

    let journeyId: UUID

    // MARK: - Repositories

    private let notesRepository: NotesRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.notesRepository = databaseManager.notesRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "NoteListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true
        notes = notesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        isLoading = false
    }

    func addNote(_ note: Note) {
        if notesRepository?.insert(note) == true {
            logger.info("Added note: \(note.id)")
            loadData()
        }
    }

    func updateNote(_ note: Note) {
        if notesRepository?.update(note) == true {
            logger.info("Updated note: \(note.id)")
            loadData()
        }
    }

    func deleteNote(_ note: Note) {
        if notesRepository?.delete(id: note.id) == true {
            logger.info("Deleted note: \(note.id)")
            loadData()
        }
    }

    // MARK: - Computed Properties

    var totalCount: Int {
        notes.count
    }
}
