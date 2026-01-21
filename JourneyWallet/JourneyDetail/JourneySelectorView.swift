import SwiftUI

struct JourneySelectorView: View {
    let journeys: [Journey]
    let selectedJourneyId: UUID?
    let onSelect: (UUID) -> Void
    let onCreateNew: () -> Void

    @State private var isExpanded: Bool = false

    private var selectedJourney: Journey? {
        journeys.first(where: { $0.id == selectedJourneyId })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Selected journey header (tappable to expand)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    if let journey = selectedJourney {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(journey.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                if !journey.destination.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin")
                                            .font(.caption)
                                        Text(journey.destination)
                                            .font(.caption)
                                    }

                                    Text("•")
                                        .font(.caption)
                                }

                                Text(formatDateRange(journey: journey))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Text(L("journey.detail.select_journey"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            // Expanded journey list
            if isExpanded {
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(journeys) { journey in
                            JourneySelectorRow(
                                journey: journey,
                                isSelected: journey.id == selectedJourneyId
                            ) {
                                onSelect(journey.id)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }

                            if journey.id != journeys.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }

                        // Create new journey button
                        Divider()

                        Button {
                            onCreateNew()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                                Text(L("journey.detail.create_new"))
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxHeight: 300)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func formatDateRange(journey: Journey) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: journey.startDate)) - \(formatter.string(from: journey.endDate))"
    }
}

struct JourneySelectorRow: View {
    let journey: Journey
    let isSelected: Bool
    let onTap: () -> Void

    private var statusColor: Color {
        if journey.isActive {
            return .green
        } else if journey.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if journey.isActive {
            return L("journey.status.active")
        } else if journey.isUpcoming {
            return L("journey.status.upcoming")
        } else {
            return L("journey.status.past")
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(journey.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        if !journey.destination.isEmpty {
                            Text(journey.destination)
                            Text("•")
                        }
                        Text(statusText)
                            .foregroundColor(statusColor)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.orange)
                        .font(.body)
                }
            }
            .padding()
            .background(isSelected ? Color.orange.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        JourneySelectorView(
            journeys: [
                Journey(name: "Paris Vacation", destination: "Paris, France", startDate: Date(), endDate: Date().addingTimeInterval(7 * 24 * 60 * 60)),
                Journey(name: "Tokyo Trip", destination: "Tokyo, Japan", startDate: Date().addingTimeInterval(30 * 24 * 60 * 60), endDate: Date().addingTimeInterval(40 * 24 * 60 * 60)),
                Journey(name: "London Business", destination: "London, UK", startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), endDate: Date().addingTimeInterval(-25 * 24 * 60 * 60))
            ],
            selectedJourneyId: nil,
            onSelect: { _ in },
            onCreateNew: {}
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGray6))
}
