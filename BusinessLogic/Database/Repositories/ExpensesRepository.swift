import Foundation
import SQLite
import os

class ExpensesRepository {
    private let table: Table

    private let idColumn = Expression<String>("id")
    private let journeyIdColumn = Expression<String>("journey_id")
    private let titleColumn = Expression<String>("title")
    private let amountColumn = Expression<String>("amount")
    private let currencyColumn = Expression<String>("currency")
    private let categoryColumn = Expression<String>("category")
    private let dateColumn = Expression<Date>("date")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "ExpensesRepository")
    }

    func fetchAll() -> [Expense] {
        var expenses: [Expense] = []

        do {
            for row in try db.prepare(table.order(dateColumn.desc)) {
                if let expense = mapRowToExpense(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch all expenses: \(error)")
        }

        return expenses
    }

    func fetchByJourneyId(journeyId: UUID) -> [Expense] {
        var expenses: [Expense] = []

        do {
            let query = table.filter(journeyIdColumn == journeyId.uuidString).order(dateColumn.desc)
            for row in try db.prepare(query) {
                if let expense = mapRowToExpense(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch expenses for journey \(journeyId): \(error)")
        }

        return expenses
    }

    func fetchById(id: UUID) -> Expense? {
        let query = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(query) {
                return mapRowToExpense(row)
            }
        } catch {
            logger.error("Failed to fetch expense by id \(id): \(error)")
        }
        return nil
    }

    func fetchByCategory(category: ExpenseCategory) -> [Expense] {
        var expenses: [Expense] = []

        do {
            let query = table.filter(categoryColumn == category.rawValue).order(dateColumn.desc)
            for row in try db.prepare(query) {
                if let expense = mapRowToExpense(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch expenses by category \(category.rawValue): \(error)")
        }

        return expenses
    }

    func fetchByJourneyIdAndCategory(journeyId: UUID, category: ExpenseCategory) -> [Expense] {
        var expenses: [Expense] = []

        do {
            let query = table.filter(
                journeyIdColumn == journeyId.uuidString && categoryColumn == category.rawValue
            ).order(dateColumn.desc)

            for row in try db.prepare(query) {
                if let expense = mapRowToExpense(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch expenses for journey and category: \(error)")
        }

        return expenses
    }

    func insert(_ expense: Expense) -> Bool {
        do {
            let insert = table.insert(
                idColumn <- expense.id.uuidString,
                journeyIdColumn <- expense.journeyId.uuidString,
                titleColumn <- expense.title,
                amountColumn <- expense.amount.description,
                currencyColumn <- expense.currency.rawValue,
                categoryColumn <- expense.category.rawValue,
                dateColumn <- expense.date,
                notesColumn <- expense.notes,
                createdAtColumn <- expense.createdAt
            )
            try db.run(insert)
            logger.info("Inserted expense: \(expense.id)")
            return true
        } catch {
            logger.error("Failed to insert expense: \(error)")
            return false
        }
    }

    func update(_ expense: Expense) -> Bool {
        let record = table.filter(idColumn == expense.id.uuidString)

        do {
            try db.run(record.update(
                titleColumn <- expense.title,
                amountColumn <- expense.amount.description,
                currencyColumn <- expense.currency.rawValue,
                categoryColumn <- expense.category.rawValue,
                dateColumn <- expense.date,
                notesColumn <- expense.notes
            ))
            logger.info("Updated expense: \(expense.id)")
            return true
        } catch {
            logger.error("Failed to update expense: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)

        do {
            try db.run(record.delete())
            logger.info("Deleted expense: \(id)")
            return true
        } catch {
            logger.error("Failed to delete expense: \(error)")
            return false
        }
    }

    func deleteByJourneyId(journeyId: UUID) -> Bool {
        let records = table.filter(journeyIdColumn == journeyId.uuidString)

        do {
            try db.run(records.delete())
            logger.info("Deleted expenses for journey: \(journeyId)")
            return true
        } catch {
            logger.error("Failed to delete expenses for journey: \(error)")
            return false
        }
    }

    func deleteAll() -> Bool {
        do {
            try db.run(table.delete())
            logger.info("Deleted all expenses")
            return true
        } catch {
            logger.error("Failed to delete all expenses: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count expenses: \(error)")
            return 0
        }
    }

    func countByJourneyId(journeyId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(journeyIdColumn == journeyId.uuidString).count)
        } catch {
            logger.error("Failed to count expenses for journey: \(error)")
            return 0
        }
    }

    func calculateTotalByJourneyId(journeyId: UUID) -> [Currency: Decimal] {
        var totals: [Currency: Decimal] = [:]
        let expenses = fetchByJourneyId(journeyId: journeyId)

        for expense in expenses {
            let currentTotal = totals[expense.currency] ?? 0
            totals[expense.currency] = currentTotal + expense.amount
        }

        return totals
    }

    func calculateTotalByCategory(journeyId: UUID) -> [ExpenseCategory: [Currency: Decimal]] {
        var totals: [ExpenseCategory: [Currency: Decimal]] = [:]
        let expenses = fetchByJourneyId(journeyId: journeyId)

        for expense in expenses {
            var categoryTotals = totals[expense.category] ?? [:]
            let currentTotal = categoryTotals[expense.currency] ?? 0
            categoryTotals[expense.currency] = currentTotal + expense.amount
            totals[expense.category] = categoryTotals
        }

        return totals
    }

    func calculateGrandTotal() -> [Currency: Decimal] {
        var totals: [Currency: Decimal] = [:]
        let expenses = fetchAll()

        for expense in expenses {
            let currentTotal = totals[expense.currency] ?? 0
            totals[expense.currency] = currentTotal + expense.amount
        }

        return totals
    }

    private func mapRowToExpense(_ row: Row) -> Expense? {
        guard let id = UUID(uuidString: row[idColumn]),
              let journeyId = UUID(uuidString: row[journeyIdColumn]),
              let amount = Decimal(string: row[amountColumn]),
              let currency = Currency(rawValue: row[currencyColumn]),
              let category = ExpenseCategory(rawValue: row[categoryColumn]) else {
            return nil
        }

        return Expense(
            id: id,
            journeyId: journeyId,
            title: row[titleColumn],
            amount: amount,
            currency: currency,
            category: category,
            date: row[dateColumn],
            notes: row[notesColumn],
            createdAt: row[createdAtColumn]
        )
    }
}
