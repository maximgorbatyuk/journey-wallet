import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case transport
    case accommodation
    case food
    case activities
    case shopping
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transport: return L("expense.category.transport")
        case .accommodation: return L("expense.category.accommodation")
        case .food: return L("expense.category.food")
        case .activities: return L("expense.category.activities")
        case .shopping: return L("expense.category.shopping")
        case .other: return L("expense.category.other")
        }
    }

    var icon: String {
        switch self {
        case .transport: return "car.fill"
        case .accommodation: return "bed.double.fill"
        case .food: return "fork.knife"
        case .activities: return "ticket.fill"
        case .shopping: return "bag.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Expense: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var title: String
    var amount: Decimal
    var currency: Currency
    var category: ExpenseCategory
    var date: Date
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        title: String,
        amount: Decimal,
        currency: Currency,
        category: ExpenseCategory = .other,
        date: Date = Date(),
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.title = title
        self.amount = amount
        self.currency = currency
        self.category = category
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
    }

    var formattedAmount: String {
        "\(currency.rawValue)\(amount)"
    }
}
