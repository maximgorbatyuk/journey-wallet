import Foundation

struct NoteLink: Codable, Identifiable, Equatable {
    let id: UUID
    let noteId: UUID
    var title: String
    var url: String
    var sortOrder: Int

    init(id: UUID = UUID(), noteId: UUID, title: String, url: String, sortOrder: Int = 0) {
        self.id = id
        self.noteId = noteId
        self.title = title
        self.url = url
        self.sortOrder = sortOrder
    }
}
