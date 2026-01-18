import SwiftUI

struct QuickAddSheet: View {

    let journeyId: UUID
    let onEntityAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntityType: QuickAddEntityType?

    private let userSettingsRepository: UserSettingsRepository?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(journeyId: UUID, onEntityAdded: @escaping () -> Void) {
        self.journeyId = journeyId
        self.onEntityAdded = onEntityAdded
        self.userSettingsRepository = DatabaseManager.shared.userSettingsRepository
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(QuickAddEntityType.allCases) { entityType in
                        QuickAddOptionButton(entityType: entityType) {
                            selectedEntityType = entityType
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L("quick_add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedEntityType) { entityType in
                formView(for: entityType)
            }
        }
    }

    @ViewBuilder
    private func formView(for entityType: QuickAddEntityType) -> some View {
        switch entityType {
        case .transport:
            TransportFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { transport in
                    if DatabaseManager.shared.transportsRepository?.insert(transport) == true {
                        onEntityAdded()
                        dismiss()
                    }
                }
            )

        case .hotel:
            HotelFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { hotel in
                    if DatabaseManager.shared.hotelsRepository?.insert(hotel) == true {
                        onEntityAdded()
                        dismiss()
                    }
                }
            )

        case .carRental:
            CarRentalFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { carRental in
                    if DatabaseManager.shared.carRentalsRepository?.insert(carRental) == true {
                        onEntityAdded()
                        dismiss()
                    }
                }
            )

        case .document:
            DocumentPickerView(journeyId: journeyId) { success in
                if success {
                    onEntityAdded()
                    dismiss()
                }
            }

        case .note:
            NoteFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { note in
                    if DatabaseManager.shared.notesRepository?.insert(note) == true {
                        onEntityAdded()
                        dismiss()
                    }
                }
            )

        case .place:
            PlaceFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { place in
                    if DatabaseManager.shared.placesToVisitRepository?.insert(place) == true {
                        onEntityAdded()
                        dismiss()
                    }
                }
            )

        case .reminder:
            ReminderFormView(
                mode: .addForJourney(journeyId),
                onSave: { reminder in
                    ReminderService.shared.createReminder(
                        journeyId: reminder.journeyId,
                        title: reminder.title,
                        reminderDate: reminder.reminderDate,
                        relatedEntityType: reminder.relatedEntityType,
                        relatedEntityId: reminder.relatedEntityId
                    )
                    onEntityAdded()
                    dismiss()
                }
            )

        case .expense:
            ExpenseFormView(
                journeyId: journeyId,
                mode: .add,
                defaultCurrency: userSettingsRepository?.fetchCurrency() ?? .usd,
                onSave: { expense in
                    if DatabaseManager.shared.expensesRepository?.insert(expense) == true {
                        onEntityAdded()
                        dismiss()
                    }
                }
            )
        }
    }

    private func placeholderView(for entityType: QuickAddEntityType) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: entityType.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(entityType.iconColor)

                Text(entityType.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(L("quick_add.coming_soon"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(entityType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        selectedEntityType = nil
                    }
                }
            }
        }
    }
}

// MARK: - Quick Add Option Button

struct QuickAddOptionButton: View {

    let entityType: QuickAddEntityType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(entityType.iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: entityType.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(entityType.iconColor)
                }

                Text(entityType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickAddSheet(journeyId: UUID(), onEntityAdded: {})
}
