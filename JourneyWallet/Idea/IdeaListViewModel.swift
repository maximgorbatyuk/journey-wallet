import Foundation
import os

@MainActor
@Observable
class IdeaListViewModel {

    // MARK: - Properties

    var ideas: [Idea] = []
    var isLoading: Bool = false

    var showAddIdeaSheet: Bool = false
    var ideaToEdit: Idea?

    let journeyId: UUID

    // MARK: - Repositories

    private let ideasRepository: IdeasRepository?
    private let journeysRepository: JourneysRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.ideasRepository = databaseManager.ideasRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "IdeaListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true
        ideas = ideasRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        isLoading = false
    }

    func addIdea(_ idea: Idea) {
        if ideasRepository?.insert(idea) == true {
            logger.info("Added idea: \(idea.id)")
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadData()
        }
    }

    func updateIdea(_ idea: Idea) {
        if ideasRepository?.update(idea) == true {
            logger.info("Updated idea: \(idea.id)")
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadData()
        }
    }

    func deleteIdea(_ idea: Idea) {
        if ideasRepository?.delete(id: idea.id) == true {
            logger.info("Deleted idea: \(idea.id)")
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadData()
        }
    }

    func toggleDone(_ idea: Idea) {
        if ideasRepository?.toggleDone(id: idea.id) == true {
            logger.info("Toggled done status for idea: \(idea.id)")
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            loadData()
        }
    }

    func moveToJourney(idea: Idea, newJourneyId: UUID) -> Bool {
        if ideasRepository?.updateJourneyId(id: idea.id, newJourneyId: newJourneyId) == true {
            logger.info("Moved idea \(idea.id) to journey \(newJourneyId)")
            journeysRepository?.touchUpdatedAt(journeyId: journeyId)
            journeysRepository?.touchUpdatedAt(journeyId: newJourneyId)
            loadData()
            return true
        }
        logger.error("Failed to move idea \(idea.id) to journey \(newJourneyId)")
        return false
    }

    // MARK: - Computed Properties

    var pendingIdeas: [Idea] {
        ideas.filter { !$0.isDone }
    }

    var doneIdeas: [Idea] {
        ideas.filter { $0.isDone }
    }

    var totalCount: Int {
        ideas.count
    }

    var doneCount: Int {
        doneIdeas.count
    }

    var progressPercentage: Double {
        guard !ideas.isEmpty else { return 0 }
        return Double(doneCount) / Double(ideas.count) * 100
    }
}
