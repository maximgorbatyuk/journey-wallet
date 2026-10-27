import Foundation

@MainActor
@Observable
final class NoteDetailViewModel {
    private(set) var note: Note?
    private(set) var links: [NoteLink] = []
    private(set) var documents: [Document] = []
    private(set) var hasMoved = false
    var errorMessage: String?

    private let noteId: UUID
    private let notesRepository: NotesRepository?
    private let journeysRepository: JourneysRepository?

    convenience init(noteId: UUID) {
        self.init(
            noteId: noteId,
            notesRepository: DatabaseManager.shared.notesRepository,
            journeysRepository: DatabaseManager.shared.journeysRepository
        )
    }

    init(noteId: UUID, notesRepository: NotesRepository?, journeysRepository: JourneysRepository? = nil) {
        self.noteId = noteId
        self.notesRepository = notesRepository
        self.journeysRepository = journeysRepository
        reload()
    }

    func reload() {
        note = notesRepository?.fetchById(id: noteId)
        links = note == nil ? [] : notesRepository?.fetchLinks(noteId: noteId) ?? []
        documents = note == nil ? [] : notesRepository?.fetchDocuments(noteId: noteId) ?? []
    }

    func canPreview(_ document: Document) -> Bool {
        guard DocumentService.shared.documentExists(fileName: document.fileName, journeyId: document.journeyId) else {
            errorMessage = L("note.document.missing")
            return false
        }
        return true
    }

    func moveNote(to journeyId: UUID) -> Bool {
        guard let note, notesRepository?.updateJourneyId(id: note.id, newJourneyId: journeyId) == true else {
            errorMessage = L("note.error.move")
            return false
        }
        journeysRepository?.touchUpdatedAt(journeyId: note.journeyId)
        journeysRepository?.touchUpdatedAt(journeyId: journeyId)
        hasMoved = true
        return true
    }
}
