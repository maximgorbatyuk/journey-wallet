import Foundation

enum ChecklistItemFilter: String, CaseIterable {
    case all
    case pending
    case completed

    var displayName: String {
        switch self {
        case .all: return L("checklist.items.filter.all")
        case .pending: return L("checklist.items.filter.pending")
        case .completed: return L("checklist.items.filter.completed")
        }
    }
}
