import SwiftUI

struct MoveToJourneySheet: View {

    let currentJourneyId: UUID
    let entityName: String
    let onMove: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    private let journeysRepository: JourneysRepository?

    @State private var journeys: [Journey] = []
    @State private var selectedJourneyId: UUID?

    init(currentJourneyId: UUID, entityName: String, onMove: @escaping (UUID) -> Void) {
        self.currentJourneyId = currentJourneyId
        self.entityName = entityName
        self.onMove = onMove
        self.journeysRepository = DatabaseManager.shared.journeysRepository
    }

    var body: some View {
        NavigationView {
            Group {
                if availableJourneys.isEmpty {
                    emptyStateView
                } else {
                    journeyListView
                }
            }
            .navigationTitle(L("move_to_journey.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("move_to_journey.move")) {
                        if let journeyId = selectedJourneyId {
                            onMove(journeyId)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedJourneyId == nil)
                }
            }
            .onAppear {
                loadJourneys()
            }
        }
    }

    private var availableJourneys: [Journey] {
        journeys.filter { $0.id != currentJourneyId }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(L("move_to_journey.no_other_journeys"))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var journeyListView: some View {
        List {
            Section(header: Text(L("move_to_journey.select_journey"))) {
                ForEach(availableJourneys) { journey in
                    JourneySelectionRow(
                        journey: journey,
                        isSelected: selectedJourneyId == journey.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedJourneyId = journey.id
                    }
                }
            }
        }
    }

    private func loadJourneys() {
        journeys = journeysRepository?.fetchAll() ?? []
    }
}

// MARK: - Journey Selection Row

private struct JourneySelectionRow: View {
    let journey: Journey
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(journey.name)
                    .font(.headline)

                Text(journey.destination)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(formatDateRange())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let startStr = formatter.string(from: journey.startDate)
        let endStr = formatter.string(from: journey.endDate)

        return "\(startStr) - \(endStr)"
    }
}
