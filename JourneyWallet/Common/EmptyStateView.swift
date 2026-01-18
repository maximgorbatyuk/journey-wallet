import SwiftUI

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Empty State Type

enum EmptyStateType {
    case journeys
    case transports
    case hotels
    case carRentals
    case documents
    case notes
    case places
    case expenses
    case reminders
    case searchResults

    var icon: String {
        switch self {
        case .journeys: return "suitcase"
        case .transports: return "airplane"
        case .hotels: return "bed.double"
        case .carRentals: return "car"
        case .documents: return "doc.text"
        case .notes: return "note.text"
        case .places: return "mappin.circle"
        case .expenses: return "creditcard"
        case .reminders: return "bell"
        case .searchResults: return "magnifyingglass"
        }
    }

    var title: String {
        switch self {
        case .journeys: return L("empty.journeys.title")
        case .transports: return L("empty.transports.title")
        case .hotels: return L("empty.hotels.title")
        case .carRentals: return L("empty.car_rentals.title")
        case .documents: return L("empty.documents.title")
        case .notes: return L("empty.notes.title")
        case .places: return L("empty.places.title")
        case .expenses: return L("empty.expenses.title")
        case .reminders: return L("empty.reminders.title")
        case .searchResults: return L("empty.search.title")
        }
    }

    var message: String {
        switch self {
        case .journeys: return L("empty.journeys.message")
        case .transports: return L("empty.transports.message")
        case .hotels: return L("empty.hotels.message")
        case .carRentals: return L("empty.car_rentals.message")
        case .documents: return L("empty.documents.message")
        case .notes: return L("empty.notes.message")
        case .places: return L("empty.places.message")
        case .expenses: return L("empty.expenses.message")
        case .reminders: return L("empty.reminders.message")
        case .searchResults: return L("empty.search.message")
        }
    }

    var actionTitle: String? {
        switch self {
        case .journeys: return L("empty.journeys.action")
        case .transports: return L("empty.transports.action")
        case .hotels: return L("empty.hotels.action")
        case .carRentals: return L("empty.car_rentals.action")
        case .documents: return L("empty.documents.action")
        case .notes: return L("empty.notes.action")
        case .places: return L("empty.places.action")
        case .expenses: return L("empty.expenses.action")
        case .reminders: return L("empty.reminders.action")
        case .searchResults: return nil
        }
    }
}

// MARK: - Typed Empty State View

struct TypedEmptyStateView: View {
    let type: EmptyStateType
    var action: (() -> Void)? = nil

    var body: some View {
        EmptyStateView(
            icon: type.icon,
            title: type.title,
            message: type.message,
            actionTitle: type.actionTitle,
            action: action
        )
    }
}

// MARK: - Compact Empty State

struct CompactEmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview("Full Empty State") {
    EmptyStateView(
        icon: "suitcase",
        title: "No Journeys Yet",
        message: "Start planning your next adventure by creating your first journey.",
        actionTitle: "Create Journey",
        action: {}
    )
}

#Preview("Typed Empty State") {
    TypedEmptyStateView(type: .transports, action: {})
}

#Preview("Compact Empty State") {
    CompactEmptyStateView(
        icon: "airplane",
        message: "No transports added yet"
    )
}
