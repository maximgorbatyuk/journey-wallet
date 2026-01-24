import Foundation
import os

@MainActor
@Observable
class ChecklistDetailViewModel {

    // MARK: - Properties

    var checklist: Checklist
    var items: [ChecklistItem] = []
    var filteredItems: [ChecklistItem] = []
    var selectedFilter: ChecklistItemFilter = .all
    var isLoading: Bool = false

    var showAddItemSheet: Bool = false
    var itemToEdit: ChecklistItem? = nil
    var showMoveCheckedConfirmation: Bool = false

    let journeyId: UUID

    // MARK: - Repositories

    private let checklistsRepository: ChecklistsRepository?
    private let checklistItemsRepository: ChecklistItemsRepository?
    private let logger: Logger

    // MARK: - Init

    init(checklist: Checklist, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.checklist = checklist
        self.journeyId = journeyId
        self.checklistsRepository = databaseManager.checklistsRepository
        self.checklistItemsRepository = databaseManager.checklistItemsRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ChecklistDetailViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true

        // Refresh checklist data
        if let updated = checklistsRepository?.fetchById(id: checklist.id) {
            checklist = updated
        }

        items = checklistItemsRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
        applyFilters()

        isLoading = false
    }

    func applyFilters() {
        switch selectedFilter {
        case .all:
            filteredItems = items
        case .pending:
            filteredItems = items.filter { !$0.isChecked }
        case .completed:
            filteredItems = items.filter { $0.isChecked }
        }
    }

    func toggleItem(_ item: ChecklistItem) {
        if checklistItemsRepository?.toggleChecked(id: item.id) == true {
            logger.info("Toggled item: \(item.id)")
            loadData()
        }
    }

    func addItem(name: String) {
        let sortingOrder = checklistItemsRepository?.getNextSortingOrder(checklistId: checklist.id) ?? 0
        let item = ChecklistItem(
            checklistId: checklist.id,
            name: name,
            sortingOrder: sortingOrder
        )

        if checklistItemsRepository?.insert(item) == true {
            logger.info("Added item: \(item.id)")
            loadData()
        }
    }

    func updateItem(_ item: ChecklistItem) {
        if checklistItemsRepository?.update(item) == true {
            logger.info("Updated item: \(item.id)")
            loadData()
        }
    }

    func deleteItem(_ item: ChecklistItem) {
        if checklistItemsRepository?.delete(id: item.id) == true {
            logger.info("Deleted item: \(item.id)")
            loadData()
        }
    }

    func updateChecklist(_ updated: Checklist) {
        if checklistsRepository?.update(updated) == true {
            checklist = updated
            logger.info("Updated checklist: \(updated.id)")
        }
    }

    func deleteChecklist() -> Bool {
        let checklistId = checklist.id
        // Delete all items first
        _ = checklistItemsRepository?.deleteByChecklistId(checklistId: checklistId)

        if checklistsRepository?.delete(id: checklistId) == true {
            logger.info("Deleted checklist: \(checklistId)")
            return true
        }
        return false
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        var updatedItems = items
        updatedItems.move(fromOffsets: source, toOffset: destination)

        // Update sorting order for all items
        for (index, var item) in updatedItems.enumerated() {
            item.sortingOrder = index
            updatedItems[index] = item
        }

        if checklistItemsRepository?.updateSortingOrders(updatedItems) == true {
            items = updatedItems
            applyFilters()
            logger.info("Reordered items")
        }
    }

    func moveCheckedItemsToEnd() {
        let uncheckedItems = items.filter { !$0.isChecked }
        let checkedItems = items.filter { $0.isChecked }

        var reorderedItems = uncheckedItems + checkedItems

        // Update sorting order for all items
        for (index, var item) in reorderedItems.enumerated() {
            item.sortingOrder = index
            reorderedItems[index] = item
        }

        if checklistItemsRepository?.updateSortingOrders(reorderedItems) == true {
            items = reorderedItems
            applyFilters()
            logger.info("Moved checked items to end")
        }
    }

    // MARK: - Computed Properties

    var progress: (checked: Int, total: Int) {
        let checked = items.filter { $0.isChecked }.count
        return (checked: checked, total: items.count)
    }

    var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.checked) / Double(progress.total)
    }

    var hasCheckedItems: Bool {
        items.contains { $0.isChecked }
    }
}
