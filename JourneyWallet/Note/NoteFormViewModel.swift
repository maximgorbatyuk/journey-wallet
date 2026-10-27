import Foundation

@MainActor
@Observable
final class NoteFormViewModel {
    let journeyId: UUID
    let noteId: UUID
    var title: String
    var content: String
    private(set) var links: [NoteLink]
    private(set) var documents: [Document]
    private(set) var availableDocuments: [Document] = []
    private(set) var attachmentsLoaded: Bool
    var errorMessage: String?

    private let existingNote: Note?
    private let notesRepository: NotesRepository?
    private let documentsRepository: DocumentsRepository?
    private let journeysRepository: JourneysRepository?

    convenience init(journeyId: UUID, mode: NoteFormMode) {
        self.init(
            journeyId: journeyId,
            mode: mode,
            notesRepository: DatabaseManager.shared.notesRepository,
            documentsRepository: DatabaseManager.shared.documentsRepository,
            journeysRepository: DatabaseManager.shared.journeysRepository
        )
    }

    init(
        journeyId: UUID,
        mode: NoteFormMode,
        notesRepository: NotesRepository?,
        documentsRepository: DocumentsRepository?,
        journeysRepository: JourneysRepository? = nil
    ) {
        self.journeyId = journeyId
        existingNote = mode.existingNote
        noteId = mode.existingNote?.id ?? UUID()
        title = mode.existingNote?.title ?? ""
        content = mode.existingNote?.content ?? ""
        self.notesRepository = notesRepository
        self.documentsRepository = documentsRepository
        self.journeysRepository = journeysRepository
        links = []
        documents = []
        attachmentsLoaded = !mode.isEditing
        if mode.isEditing {
            retryLoadingAttachments()
        }
        refreshAvailableDocuments()
    }

    func retryLoadingAttachments() {
        guard existingNote != nil else { return }
        attachmentsLoaded = false
        guard let notesRepository else {
            errorMessage = L("note.error.load")
            return
        }
        do {
            let attachments = try notesRepository.loadAttachments(noteId: noteId)
            links = attachments.links
            documents = attachments.documents
            attachmentsLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = L("note.error.load")
        }
    }

    func refreshAvailableDocuments() {
        guard attachmentsLoaded else {
            availableDocuments = []
            return
        }
        availableDocuments = documentsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
    }

    @discardableResult
    func upsertLink(id: UUID?, title: String, url: String) -> Bool {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let address = NoteLinkURL.normalized(url) else { return false }
        if let index = links.firstIndex(where: { $0.id == id }) {
            links[index] = NoteLink(
                id: links[index].id,
                noteId: noteId,
                title: name,
                url: address.absoluteString,
                sortOrder: index
            )
        } else {
            links.append(NoteLink(
                id: id ?? UUID(),
                noteId: noteId,
                title: name,
                url: address.absoluteString,
                sortOrder: links.count
            ))
        }
        return true
    }

    func removeLink(id: UUID) {
        links.removeAll { $0.id == id }
        links = links.enumerated().map { index, link in
            NoteLink(id: link.id, noteId: noteId, title: link.title, url: link.url, sortOrder: index)
        }
    }

    func removeDocument(id: UUID) {
        documents.removeAll { $0.id == id }
    }

    func selectDocuments(ids: Set<UUID>) {
        documents = documents.filter { ids.contains($0.id) }
        for document in availableDocuments
            where ids.contains(document.id) && !documents.contains(where: { $0.id == document.id }) {
            documents.append(document)
        }
    }

    func attachImportedDocuments(_ imported: [Document]) {
        for document in imported
            where document.journeyId == journeyId && !documents.contains(where: { $0.id == document.id }) {
            documents.append(document)
        }
        refreshAvailableDocuments()
    }

    func save() -> Note? {
        guard attachmentsLoaded else {
            errorMessage = L("note.error.load")
            return nil
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty || !trimmedContent.isEmpty || !links.isEmpty || !documents.isEmpty else {
            errorMessage = L("note.form.validation.empty")
            return nil
        }
        let note = Note(
            id: noteId, journeyId: journeyId, title: trimmedTitle, content: trimmedContent,
            createdAt: existingNote?.createdAt ?? Date(), updatedAt: Date()
        )
        guard notesRepository?.save(note, links: links, documentIds: documents.map(\.id)) == true else {
            errorMessage = L("note.error.save")
            return nil
        }
        journeysRepository?.touchUpdatedAt(journeyId: journeyId)
        errorMessage = nil
        return note
    }
}
