import Foundation

struct Idea: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var title: String
    var description: String?
    var url: String?
    var isDone: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        title: String,
        description: String? = nil,
        url: String? = nil,
        isDone: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.title = title
        self.description = description
        self.url = url
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Generates shareable text for the idea
    var shareText: String {
        var text = L("idea.share.prefix") + " " + title
        if let description = description, !description.isEmpty {
            text += "\n" + description
        }
        if let url = url, !url.isEmpty {
            text += "\n" + url
        }
        return text
    }
}
