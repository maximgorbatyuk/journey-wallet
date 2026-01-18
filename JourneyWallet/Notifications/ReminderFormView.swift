import SwiftUI

enum ReminderFormMode: Identifiable {
    case add
    case addForJourney(UUID)
    case edit(Reminder)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .addForJourney(let journeyId):
            return "add-\(journeyId.uuidString)"
        case .edit(let reminder):
            return reminder.id.uuidString
        }
    }
}

struct ReminderFormView: View {

    let mode: ReminderFormMode
    let onSave: (Reminder) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var reminderDate: Date = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var selectedJourneyId: UUID?
    @State private var selectedEntityType: ReminderEntityType = .custom
    @State private var hasRelatedEntity: Bool = false

    @State private var journeys: [Journey] = []
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""

    private let journeysRepository: JourneysRepository?

    init(mode: ReminderFormMode, onSave: @escaping (Reminder) -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.journeysRepository = DatabaseManager.shared.journeysRepository
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section(header: Text(L("reminder.form.title_section"))) {
                    TextField(L("reminder.form.title_placeholder"), text: $title)
                }

                // Journey selection
                Section(header: Text(L("reminder.form.journey_section"))) {
                    Picker(L("reminder.form.journey"), selection: $selectedJourneyId) {
                        Text(L("reminder.form.select_journey")).tag(nil as UUID?)
                        ForEach(journeys) { journey in
                            Text(journey.name).tag(journey.id as UUID?)
                        }
                    }
                }

                // Date and time section
                Section(header: Text(L("reminder.form.datetime_section"))) {
                    DatePicker(
                        L("reminder.form.date"),
                        selection: $reminderDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    // Quick date buttons
                    quickDateButtons
                }

                // Related entity section
                Section(header: Text(L("reminder.form.related_section"))) {
                    Toggle(L("reminder.form.has_related_entity"), isOn: $hasRelatedEntity)

                    if hasRelatedEntity {
                        Picker(L("reminder.form.entity_type"), selection: $selectedEntityType) {
                            ForEach(ReminderEntityType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                    }
                }

                // Info section for edit mode
                if case .edit(let reminder) = mode {
                    Section(header: Text(L("reminder.form.info_section"))) {
                        HStack {
                            Text(L("reminder.form.created"))
                            Spacer()
                            Text(formatDate(reminder.createdAt))
                                .foregroundColor(.secondary)
                        }

                        if reminder.isCompleted {
                            HStack {
                                Text(L("reminder.form.status"))
                                Spacer()
                                Label(L("reminder.status.completed"), systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveReminder()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadJourneys()
                populateFieldsIfEditing()
            }
            .alert(L("reminder.form.validation_error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) { }
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    // MARK: - Quick Date Buttons

    private var quickDateButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickDateButton(title: L("reminder.quick.1h"), action: {
                    reminderDate = Date().addingTimeInterval(3600)
                })

                QuickDateButton(title: L("reminder.quick.3h"), action: {
                    reminderDate = Date().addingTimeInterval(10800)
                })

                QuickDateButton(title: L("reminder.quick.tomorrow"), action: {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    components.day! += 1
                    components.hour = 9
                    components.minute = 0
                    if let date = Calendar.current.date(from: components) {
                        reminderDate = date
                    }
                })

                QuickDateButton(title: L("reminder.quick.next_week"), action: {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    components.day! += 7
                    components.hour = 9
                    components.minute = 0
                    if let date = Calendar.current.date(from: components) {
                        reminderDate = date
                    }
                })
            }
        }
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        switch mode {
        case .add, .addForJourney:
            return L("reminder.form.add_title")
        case .edit:
            return L("reminder.form.edit_title")
        }
    }

    // MARK: - Data Loading

    private func loadJourneys() {
        journeys = journeysRepository?.fetchAll() ?? []

        // Auto-select first journey if none selected
        if selectedJourneyId == nil && !journeys.isEmpty {
            selectedJourneyId = journeys.first?.id
        }
    }

    private func populateFieldsIfEditing() {
        switch mode {
        case .add:
            // Auto-select first journey if available (done in loadJourneys)
            break
        case .addForJourney(let journeyId):
            selectedJourneyId = journeyId
        case .edit(let reminder):
            title = reminder.title
            reminderDate = reminder.reminderDate
            selectedJourneyId = reminder.journeyId
            hasRelatedEntity = reminder.relatedEntityType != nil
            selectedEntityType = reminder.relatedEntityType ?? .custom
        }
    }

    // MARK: - Save

    private func saveReminder() {
        // Validation
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationErrorMessage = L("reminder.form.error.title_required")
            showValidationError = true
            return
        }

        guard let journeyId = selectedJourneyId else {
            validationErrorMessage = L("reminder.form.error.journey_required")
            showValidationError = true
            return
        }

        guard reminderDate > Date() else {
            validationErrorMessage = L("reminder.form.error.date_past")
            showValidationError = true
            return
        }

        let reminder: Reminder

        switch mode {
        case .add, .addForJourney:
            reminder = Reminder(
                journeyId: journeyId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                reminderDate: reminderDate,
                relatedEntityType: hasRelatedEntity ? selectedEntityType : nil,
                relatedEntityId: nil
            )
        case .edit(let existingReminder):
            reminder = Reminder(
                id: existingReminder.id,
                journeyId: journeyId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                reminderDate: reminderDate,
                isCompleted: existingReminder.isCompleted,
                relatedEntityType: hasRelatedEntity ? selectedEntityType : nil,
                relatedEntityId: existingReminder.relatedEntityId,
                notificationId: existingReminder.notificationId,
                createdAt: existingReminder.createdAt
            )
        }

        onSave(reminder)
        dismiss()
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Quick Date Button

struct QuickDateButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReminderFormView(mode: .add) { _ in }
}
