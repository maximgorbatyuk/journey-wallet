import Foundation
import os

@MainActor
@Observable
class ChecklistsListViewModel {

    // MARK: - Properties

    var checklists: [Checklist] = []
    var checklistProgress: [UUID: (checked: Int, total: Int)] = [:]
    var isLoading: Bool = false

    var showAddChecklistSheet: Bool = false
    var checklistToEdit: Checklist? = nil
    var checklistToView: Checklist? = nil

    let journeyId: UUID
    var journey: Journey?

    // MARK: - Repositories

    private let checklistsRepository: ChecklistsRepository?
    private let checklistItemsRepository: ChecklistItemsRepository?
    private let journeysRepository: JourneysRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.checklistsRepository = databaseManager.checklistsRepository
        self.checklistItemsRepository = databaseManager.checklistItemsRepository
        self.journeysRepository = databaseManager.journeysRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ChecklistsListViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true

        journey = journeysRepository?.fetchById(id: journeyId)
        checklists = checklistsRepository?.fetchByJourneyId(journeyId: journeyId) ?? []

        // Load progress for each checklist
        checklistProgress = [:]
        for checklist in checklists {
            let total = checklistItemsRepository?.countByChecklistId(checklistId: checklist.id) ?? 0
            let checked = checklistItemsRepository?.countCheckedByChecklistId(checklistId: checklist.id) ?? 0
            checklistProgress[checklist.id] = (checked: checked, total: total)
        }

        isLoading = false
    }

    func addChecklist(name: String) {
        let sortingOrder = checklistsRepository?.getNextSortingOrder(journeyId: journeyId) ?? 0
        let checklist = Checklist(
            journeyId: journeyId,
            name: name,
            sortingOrder: sortingOrder
        )

        if checklistsRepository?.insert(checklist) == true {
            logger.info("Added checklist: \(checklist.id)")
            loadData()
        }
    }

    func updateChecklist(_ checklist: Checklist) {
        if checklistsRepository?.update(checklist) == true {
            logger.info("Updated checklist: \(checklist.id)")
            loadData()
        }
    }

    func deleteChecklist(_ checklist: Checklist) {
        // Delete all items in the checklist first
        _ = checklistItemsRepository?.deleteByChecklistId(checklistId: checklist.id)

        if checklistsRepository?.delete(id: checklist.id) == true {
            logger.info("Deleted checklist: \(checklist.id)")
            loadData()
        }
    }

    func getProgress(for checklistId: UUID) -> (checked: Int, total: Int) {
        return checklistProgress[checklistId] ?? (checked: 0, total: 0)
    }

    func moveChecklist(from source: IndexSet, to destination: Int) {
        var updatedChecklists = checklists
        updatedChecklists.move(fromOffsets: source, toOffset: destination)

        // Update sorting order for all affected checklists
        for (index, var checklist) in updatedChecklists.enumerated() {
            checklist.sortingOrder = index
            updatedChecklists[index] = checklist
        }

        if checklistsRepository?.updateSortingOrders(updatedChecklists) == true {
            checklists = updatedChecklists
            logger.info("Reordered checklists")
        }
    }

    // MARK: - Computed Properties

    var totalProgress: (checked: Int, total: Int) {
        let totalChecked = checklistItemsRepository?.countCheckedByJourneyId(journeyId: journeyId) ?? 0
        let totalItems = checklistItemsRepository?.countTotalByJourneyId(journeyId: journeyId) ?? 0
        return (checked: totalChecked, total: totalItems)
    }
}
