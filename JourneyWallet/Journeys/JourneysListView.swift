import SwiftUI

struct JourneysListView: View {

    @State private var viewModel = JourneysListViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Buttons
                filterSection
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredJourneys.isEmpty {
                    emptyStateView
                } else {
                    journeysList
                }
            }
            .navigationTitle(L("journeys.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        analytics.trackEvent("add_journey_button_clicked", properties: [
                            "screen": "journeys_list_screen"
                        ])
                        viewModel.showAddJourneySheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                analytics.trackScreen("journeys_list_screen")
                viewModel.loadJourneys()
            }
            .refreshable {
                viewModel.loadJourneys()
            }
            .sheet(isPresented: $viewModel.showAddJourneySheet) {
                JourneyFormView(
                    mode: .add,
                    onSave: { journey in
                        viewModel.addJourney(journey)
                    }
                )
            }
            .sheet(item: $viewModel.journeyToEdit) { journey in
                JourneyFormView(
                    mode: .edit(journey),
                    onSave: { updatedJourney in
                        viewModel.updateJourney(updatedJourney)
                    }
                )
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JourneyFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        viewModel.applyFilter()
                    }
                }
            }
        }
    }

    // MARK: - Journeys List

    private var journeysList: some View {
        List {
            ForEach(viewModel.filteredJourneys) { journey in
                JourneyListRow(journey: journey)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Will navigate to detail view in Phase 4
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteJourney(journey)
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.journeyToEdit = journey
                        } label: {
                            Label(L("Edit"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "suitcase")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(L("journeys.empty.title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text(L("journeys.empty.subtitle"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddJourneySheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text(L("journeys.empty.add_button"))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Journey List Row

struct JourneyListRow: View {
    let journey: Journey

    private var statusColor: Color {
        if journey.isActive {
            return .green
        } else if journey.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(journey.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(journey.destination)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(formatDateRange(journey: journey))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(journey.durationDays)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Text(L("journey.days"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDateRange(journey: Journey) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: journey.startDate)) - \(formatter.string(from: journey.endDate))"
    }
}

#Preview {
    JourneysListView()
}
