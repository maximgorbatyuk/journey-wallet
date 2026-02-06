import SwiftUI

enum RoadmapStopFormMode: Identifiable {
    case add
    case edit(RoadmapStop)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let stop): return stop.id.uuidString
        }
    }
}

struct RoadmapStopFormView: View {

    let journeyId: UUID
    let mode: RoadmapStopFormMode
    let nextSortOrder: Int
    let onSave: (RoadmapStop) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var hasArrivalDate: Bool = false
    @State private var arrivalDate: Date = Date()
    @State private var hasDepartureDate: Bool = false
    @State private var departureDate: Date = Date()
    @State private var notes: String = ""

    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? L("roadmap.edit_stop") : L("roadmap.add_stop")
    }

    init(journeyId: UUID, mode: RoadmapStopFormMode, nextSortOrder: Int, onSave: @escaping (RoadmapStop) -> Void) {
        self.journeyId = journeyId
        self.mode = mode
        self.nextSortOrder = nextSortOrder
        self.onSave = onSave

        if case .edit(let stop) = mode {
            _title = State(initialValue: stop.title)
            _subtitle = State(initialValue: stop.subtitle ?? "")
            _hasArrivalDate = State(initialValue: stop.arrivalDate != nil)
            _arrivalDate = State(initialValue: stop.arrivalDate ?? Date())
            _hasDepartureDate = State(initialValue: stop.departureDate != nil)
            _departureDate = State(initialValue: stop.departureDate ?? Date())
            _notes = State(initialValue: stop.notes ?? "")
        } else {
            // Set default dates from journey
            if let journey = DatabaseManager.shared.journeysRepository?.fetchById(id: journeyId) {
                _arrivalDate = State(initialValue: journey.startDate)
                _departureDate = State(initialValue: journey.endDate)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section(header: Text(L("roadmap.stop.title"))) {
                    TextField(L("roadmap.stop.title"), text: $title)
                }

                // Subtitle Section
                Section(header: Text(L("roadmap.stop.subtitle"))) {
                    TextField(L("roadmap.stop.subtitle"), text: $subtitle)
                }

                // Arrival Date Section
                Section(header: Text(L("roadmap.stop.arrival_date"))) {
                    Toggle(L("roadmap.stop.arrival_date"), isOn: $hasArrivalDate)

                    if hasArrivalDate {
                        DatePicker(
                            L("roadmap.stop.arrival_date"),
                            selection: $arrivalDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Departure Date Section
                Section(header: Text(L("roadmap.stop.departure_date"))) {
                    Toggle(L("roadmap.stop.departure_date"), isOn: $hasDepartureDate)

                    if hasDepartureDate {
                        DatePicker(
                            L("roadmap.stop.departure_date"),
                            selection: $departureDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Notes Section
                Section(header: Text(L("roadmap.stop.notes"))) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
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
                        saveStop()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("Error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Save

    private func saveStop() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationMessage = L("roadmap.stop.title")
            showValidationError = true
            return
        }

        let stop: RoadmapStop

        if case .edit(let existingStop) = mode {
            stop = RoadmapStop(
                id: existingStop.id,
                journeyId: journeyId,
                title: trimmedTitle,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                arrivalDate: hasArrivalDate ? arrivalDate : nil,
                departureDate: hasDepartureDate ? departureDate : nil,
                sortOrder: existingStop.sortOrder,
                outgoingTransportId: existingStop.outgoingTransportId,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existingStop.createdAt,
                updatedAt: Date()
            )
        } else {
            stop = RoadmapStop(
                journeyId: journeyId,
                title: trimmedTitle,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                arrivalDate: hasArrivalDate ? arrivalDate : nil,
                departureDate: hasDepartureDate ? departureDate : nil,
                sortOrder: nextSortOrder,
                notes: notes.isEmpty ? nil : notes
            )
        }

        onSave(stop)
        dismiss()
    }
}
