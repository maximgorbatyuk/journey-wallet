import Foundation

struct NoteDocumentAttachment: Codable, Equatable {
    let noteId: UUID
    let documentId: UUID
    var sortOrder: Int

    init(noteId: UUID, documentId: UUID, sortOrder: Int = 0) {
        self.noteId = noteId
        self.documentId = documentId
        self.sortOrder = sortOrder
    }
}
