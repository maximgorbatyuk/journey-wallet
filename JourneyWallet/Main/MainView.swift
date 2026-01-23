import SwiftUI

struct MainView: View {

    @State private var viewModel = MainViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    searchBarSection

                    if viewModel.isSearching && !viewModel.searchResults.isEmpty {
                        // Search Results
                        searchResultsSection
                    } else if !viewModel.isSearching {
                        // Stats Cards
                        statsSection

                        // Extended Stats Section (always visible)
                        extendedStatsSection

                        // Active & Upcoming Journeys
                        activeJourneysSection
                    } else if viewModel.isSearching && viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                        // No search results
                        noSearchResultsView
                    }
                }
                .padding()
            }
            .navigationTitle(L("main.title"))
            .onAppear {
                analytics.trackScreen("main_screen")
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(L("main.search.placeholder"), text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .focused($isSearchFieldFocused)
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.search()
                }

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.clearSearch()
                    isSearchFieldFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("main.stats.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                StatCardView(
                    title: L("main.stats.total_journeys"),
                    value: "\(viewModel.totalJourneysCount)",
                    icon: "suitcase.fill",
                    color: .orange
                )

                StatCardView(
                    title: L("main.stats.upcoming"),
                    value: "\(viewModel.upcomingTripsCount)",
                    icon: "calendar",
                    color: .blue
                )

                StatCardView(
                    title: L("main.stats.destinations"),
                    value: "\(viewModel.totalDestinations)",
                    icon: "mappin.circle.fill",
                    color: .green
                )
            }
        }
    }

    // MARK: - Extended Stats Section

    private var extendedStatsSection: some View {
        VStack(spacing: 16) {
            // Quick Insights
            if let overviewStats = viewModel.overviewStats,
               overviewStats.totalJourneys > 0 {
                QuickInsightsCard(
                    totalTravelDays: viewModel.totalTravelDays,
                    longestJourney: viewModel.longestJourney,
                    mostVisitedDestination: viewModel.mostVisitedDestination
                )
            }

            // Extended Stats (Transport Breakdown)
            if let overviewStats = viewModel.overviewStats,
               let transportStats = viewModel.transportStats {
                ExtendedStatsSection(
                    statistics: overviewStats,
                    transportStats: transportStats
                )
            }
        }
    }

    // MARK: - Active Journeys Section

    private var activeJourneysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("main.active_journeys.title"))
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()
            }

            let activeAndUpcoming = viewModel.getActiveAndUpcomingJourneys()

            if activeAndUpcoming.isEmpty {
                emptyJourneysView
            } else {
                ForEach(activeAndUpcoming) { journey in
                    NavigationLink(destination: JourneyDetailView(initialJourneyId: journey.id)) {
                        JourneyCardView(journey: journey)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("main.search.results_title"))
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(viewModel.searchResults) { result in
                searchResultNavigationLink(for: result)
            }
        }
    }

    @ViewBuilder
    private func searchResultNavigationLink(for result: SearchResult) -> some View {
        switch result.type {
        case .journey:
            if viewModel.getJourney(by: result.id) != nil {
                NavigationLink(destination: JourneyDetailView(initialJourneyId: result.id)) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        case .transport:
            if let transport = viewModel.getTransport(by: result.id),
               let journeyId = result.journeyId {
                NavigationLink(destination: TransportDetailView(transport: transport, journeyId: journeyId)) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        case .hotel:
            if let hotel = viewModel.getHotel(by: result.id),
               let journeyId = result.journeyId {
                NavigationLink(destination: HotelDetailView(hotel: hotel, journeyId: journeyId)) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        case .carRental:
            if let carRental = viewModel.getCarRental(by: result.id),
               let journeyId = result.journeyId {
                NavigationLink(destination: CarRentalDetailView(carRental: carRental, journeyId: journeyId)) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        case .place:
            if let place = viewModel.getPlace(by: result.id),
               let journeyId = result.journeyId {
                NavigationLink(destination: PlaceFormView(
                    journeyId: journeyId,
                    mode: .edit(place),
                    onSave: { _ in }
                )) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        case .note:
            if let note = viewModel.getNote(by: result.id),
               let journeyId = result.journeyId {
                NavigationLink(destination: NoteFormView(
                    journeyId: journeyId,
                    mode: .edit(note),
                    onSave: { _ in }
                )) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        case .document:
            if let document = viewModel.getDocument(by: result.id),
               let journeyId = result.journeyId {
                NavigationLink(destination: DocumentListView(
                    journeyId: journeyId,
                    initialDocumentToOpen: document
                )) {
                    SearchResultRow(result: result)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty States

    private var emptyJourneysView: some View {
        VStack(spacing: 16) {
            Image(systemName: "suitcase")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(L("main.empty.title"))
                .font(.headline)
                .foregroundColor(.gray)

            Text(L("main.empty.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(L("main.search.no_results"))
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Stat Card View

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Journey Card View

struct JourneyCardView: View {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(journey.name)
                        .font(.headline)

                    if !journey.destination.isEmpty {
                        HStack {
                            Image(systemName: "mappin")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(journey.destination)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }

            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatDateRange(start: journey.startDate, end: journey.endDate))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(journey.durationDays) \(L("journey.days"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.type.icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let journeyName = result.journeyName {
                    HStack(spacing: 4) {
                        Image(systemName: "suitcase")
                            .font(.caption2)
                        Text(journeyName)
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    MainView()
}
