import Foundation
import os

@MainActor
@Observable
class IdeaDetailViewModel {

    // MARK: - Properties

    var idea: Idea
    let journeyId: UUID
    var roadmapAttachment: RoadmapStopAttachment?
    var attachedStopTitle: String?

    // MARK: - Repositories

    private let ideasRepository: IdeasRepository?
    private let roadmapStopAttachmentsRepository: RoadmapStopAttachmentsRepository?
    private let roadmapStopsRepository: RoadmapStopsRepository?
    private let logger: Logger

    // MARK: - Init

    init(idea: Idea, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.idea = idea
        self.journeyId = journeyId
        self.ideasRepository = databaseManager.ideasRepository
        self.roadmapStopAttachmentsRepository = databaseManager.roadmapStopAttachmentsRepository
        self.roadmapStopsRepository = databaseManager.roadmapStopsRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "IdeaDetailViewModel")
        loadRoadmapAttachment()
    }

    // MARK: - Public Methods

    func updateIdea(_ updatedIdea: Idea) {
        if ideasRepository?.update(updatedIdea) == true {
            idea = updatedIdea
            // Refresh to get updated timestamp
            if let refreshed = ideasRepository?.fetchById(id: idea.id) {
                idea = refreshed
            }
            logger.info("Updated idea: \(self.idea.id)")
        } else {
            logger.error("Failed to update idea: \(self.idea.id)")
        }
    }

    func deleteIdea() -> Bool {
        if ideasRepository?.delete(id: idea.id) == true {
            logger.info("Deleted idea: \(self.idea.id)")
            return true
        } else {
            logger.error("Failed to delete idea: \(self.idea.id)")
            return false
        }
    }

    func toggleDone() {
        if ideasRepository?.toggleDone(id: idea.id) == true {
            idea.isDone.toggle()
            // Refresh to get updated timestamp
            if let refreshed = ideasRepository?.fetchById(id: idea.id) {
                idea = refreshed
            }
            logger.info("Toggled done status for idea: \(self.idea.id)")
        } else {
            logger.error("Failed to toggle done status for idea: \(self.idea.id)")
        }
    }

    func moveToJourney(_ newJourneyId: UUID) -> Bool {
        guard ideasRepository?.updateJourneyId(id: idea.id, newJourneyId: newJourneyId) == true else {
            logger.error("Failed to move idea to new journey")
            return false
        }

        logger.info("Moved idea \(self.idea.id) to journey \(newJourneyId)")
        return true
    }

    func loadRoadmapAttachment() {
        roadmapAttachment = roadmapStopAttachmentsRepository?.fetchByEntityId(
            entityId: idea.id,
            entityType: RoadmapEntityType.idea.rawValue
        )
        if let attachment = roadmapAttachment,
           let stop = roadmapStopsRepository?.fetchById(id: attachment.roadmapStopId) {
            attachedStopTitle = stop.title
        } else {
            attachedStopTitle = nil
        }
    }

    func detachFromRoadmap() {
        guard let attachment = roadmapAttachment else { return }
        if roadmapStopAttachmentsRepository?.delete(id: attachment.id) == true {
            roadmapAttachment = nil
            attachedStopTitle = nil
            logger.info("Detached idea from roadmap: \(self.idea.id)")
        }
    }
}
