import SwiftUI

enum JourneyFormMode: Identifiable {
    case add
    case edit(Journey)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let journey): return journey.id.uuidString
        }
    }
}

struct JourneyFormView: View {
    let mode: JourneyFormMode
    let onSave: (Journey) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var notes: String = ""

    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? L("journey.form.edit_title") : L("journey.form.add_title")
    }

    init(mode: JourneyFormMode, onSave: @escaping (Journey) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let journey) = mode {
            _name = State(initialValue: journey.name)
            _destination = State(initialValue: journey.destination)
            _startDate = State(initialValue: journey.startDate)
            _endDate = State(initialValue: journey.endDate)
            _notes = State(initialValue: journey.notes ?? "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L("journey.form.section.basic"))) {
                    TextField(L("journey.form.name"), text: $name)
                        .textContentType(.name)

                    TextField(L("journey.form.destination"), text: $destination)
                        .textContentType(.addressCity)
                }

                Section(header: Text(L("journey.form.section.dates"))) {
                    DatePicker(
                        L("journey.form.start_date"),
                        selection: $startDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        L("journey.form.end_date"),
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }

                Section(header: Text(L("journey.form.section.notes"))) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
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
                        saveJourney()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("Error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                let screenName = isEditing ? "journey_edit_screen" : "journey_add_screen"
                analytics.trackScreen(screenName)
            }
        }
    }

    private func validateForm() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("journey.form.error.name_required")
            showValidationError = true
            return false
        }

        if destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("journey.form.error.destination_required")
            showValidationError = true
            return false
        }

        if endDate < startDate {
            validationMessage = L("journey.form.error.invalid_dates")
            showValidationError = true
            return false
        }

        return true
    }

    private func saveJourney() {
        guard validateForm() else { return }

        let journey: Journey

        if case .edit(let existingJourney) = mode {
            journey = Journey(
                id: existingJourney.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: startDate,
                endDate: endDate,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existingJourney.createdAt,
                updatedAt: Date()
            )
        } else {
            journey = Journey(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: startDate,
                endDate: endDate,
                notes: notes.isEmpty ? nil : notes
            )
        }

        onSave(journey)
        dismiss()
    }
}

#Preview("Add Journey") {
    JourneyFormView(mode: .add) { _ in }
}

#Preview("Edit Journey") {
    JourneyFormView(
        mode: .edit(Journey(
            name: "Summer Trip",
            destination: "Paris, France",
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            notes: "Looking forward to this!"
        ))
    ) { _ in }
}
