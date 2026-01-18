import Foundation
import os

/// Filter options for expenses list
enum ExpenseFilter: String, CaseIterable {
    case all
    case transport
    case accommodation
    case food
    case activities
    case shopping
    case other

    var displayName: String {
        switch self {
        case .all: return L("expense.filter.all")
        case .transport: return L("expense.category.transport")
        case .accommodation: return L("expense.category.accommodation")
        case .food: return L("expense.category.food")
        case .activities: return L("expense.category.activities")
        case .shopping: return L("expense.category.shopping")
        case .other: return L("expense.category.other")
        }
    }

    var category: ExpenseCategory? {
        switch self {
        case .all: return nil
        case .transport: return .transport
        case .accommodation: return .accommodation
        case .food: return .food
        case .activities: return .activities
        case .shopping: return .shopping
        case .other: return .other
        }
    }
}

@MainActor
@Observable
class BudgetViewModel {

    // MARK: - Properties

    var expenses: [Expense] = []
    var filteredExpenses: [Expense] = []
    var selectedFilter: ExpenseFilter = .all
    var isLoading: Bool = false

    var showAddExpenseSheet: Bool = false
    var expenseToEdit: Expense? = nil

    let journeyId: UUID

    // MARK: - Repositories

    private let expensesRepository: ExpensesRepository?
    private let logger: Logger

    // MARK: - Init

    init(journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.journeyId = journeyId
        self.expensesRepository = databaseManager.expensesRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "BudgetViewModel")
    }

    // MARK: - Public Methods

    func loadData() {
        isLoading = true
        expenses = expensesRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        applyFilters()
        isLoading = false
    }

    func applyFilters() {
        var result = expenses

        // Apply category filter
        if let category = selectedFilter.category {
            result = result.filter { $0.category == category }
        }

        // Sort by date (newest first)
        filteredExpenses = result.sorted { $0.date > $1.date }
    }

    func addExpense(_ expense: Expense) {
        if expensesRepository?.insert(expense) == true {
            logger.info("Added expense: \(expense.id)")
            loadData()
        }
    }

    func updateExpense(_ expense: Expense) {
        if expensesRepository?.update(expense) == true {
            logger.info("Updated expense: \(expense.id)")
            loadData()
        }
    }

    func deleteExpense(_ expense: Expense) {
        if expensesRepository?.delete(id: expense.id) == true {
            logger.info("Deleted expense: \(expense.id)")
            loadData()
        }
    }

    // MARK: - Computed Properties

    var totalCount: Int {
        filteredExpenses.count
    }

    /// Total expenses by currency
    var totalByCurrency: [Currency: Decimal] {
        expensesRepository?.calculateTotalByJourneyId(journeyId: journeyId) ?? [:]
    }

    /// Total expenses by category and currency
    var totalByCategory: [ExpenseCategory: [Currency: Decimal]] {
        expensesRepository?.calculateTotalByCategory(journeyId: journeyId) ?? [:]
    }

    /// Formatted total string for display
    var formattedTotal: String {
        let totals = totalByCurrency
        if totals.isEmpty { return "-" }

        return totals.map { currency, amount in
            "\(currency.rawValue)\(formatAmount(amount))"
        }.joined(separator: " • ")
    }

    /// Category breakdown for chart
    var categoryBreakdown: [(category: ExpenseCategory, amount: Decimal, currency: Currency)] {
        var breakdown: [(category: ExpenseCategory, amount: Decimal, currency: Currency)] = []

        for (category, currencyAmounts) in totalByCategory {
            for (currency, amount) in currencyAmounts {
                breakdown.append((category: category, amount: amount, currency: currency))
            }
        }

        return breakdown.sorted { $0.amount > $1.amount }
    }

    // MARK: - Private Methods

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
