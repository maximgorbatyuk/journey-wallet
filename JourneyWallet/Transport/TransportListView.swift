import SwiftUI

struct TransportListView: View {

    let journeyId: UUID

    @State private var viewModel: TransportListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: TransportListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter section
            filterSection
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Type filter pills
            if !viewModel.transports.isEmpty {
                typeFilterSection
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredTransports.isEmpty {
                emptyStateView
            } else {
                transportList
            }
        }
        .navigationTitle(L("transport.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_transport_button_clicked", properties: [
                        "screen": "transport_list_screen"
                    ])
                    viewModel.showAddTransportSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("transport_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddTransportSheet) {
            TransportFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { transport in
                    viewModel.addTransport(transport)
                }
            )
        }
        .sheet(item: $viewModel.transportToEdit) { transport in
            TransportFormView(
                journeyId: journeyId,
                mode: .edit(transport),
                onSave: { updatedTransport in
                    viewModel.updateTransport(updatedTransport)
                }
            )
        }
        .sheet(item: $viewModel.transportToView) { transport in
            NavigationView {
                TransportDetailView(transport: transport, journeyId: journeyId)
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransportFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        viewModel.applyFilters()
                    }
                }
            }
        }
    }

    // MARK: - Type Filter Section

    private var typeFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All types button
                TypeFilterChip(
                    title: L("transport.filter.all_types"),
                    iconName: "list.bullet",
                    color: .gray,
                    isSelected: viewModel.selectedTypeFilter == nil
                ) {
                    viewModel.selectedTypeFilter = nil
                    viewModel.applyFilters()
                }

                // Individual type buttons
                ForEach(TransportType.allCases, id: \.self) { type in
                    TypeFilterChip(
                        title: type.displayName,
                        iconName: type.iconName,
                        color: type.color,
                        isSelected: viewModel.selectedTypeFilter == type
                    ) {
                        viewModel.selectedTypeFilter = type
                        viewModel.applyFilters()
                    }
                }
            }
        }
    }

    // MARK: - Transport List

    private var transportList: some View {
        List {
            ForEach(viewModel.activeTypes, id: \.self) { type in
                Section(header: transportSectionHeader(type: type)) {
                    ForEach(viewModel.transportsByType[type] ?? []) { transport in
                        TransportListRow(transport: transport)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.transportToView = transport
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteTransport(transport)
                                } label: {
                                    Label(L("Delete"), systemImage: "trash")
                                }

                                Button {
                                    viewModel.transportToEdit = transport
                                } label: {
                                    Label(L("Edit"), systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func transportSectionHeader(type: TransportType) -> some View {
        HStack(spacing: 8) {
            Image(systemName: type.iconName)
                .foregroundColor(type.color)
            Text(type.displayName)
                .font(.headline)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(L("transport.list.empty.title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text(L("transport.list.empty.subtitle"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddTransportSheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text(L("transport.list.empty.add_button"))
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

// MARK: - Type Filter Chip

struct TypeFilterChip: View {
    let title: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Transport List Row

struct TransportListRow: View {
    let transport: Transport

    private var statusColor: Color {
        if transport.isInProgress {
            return .green
        } else if transport.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type icon with status indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: transport.type.iconName)
                    .font(.title2)
                    .foregroundColor(transport.type.color)
                    .frame(width: 40, height: 40)
                    .background(transport.type.color.opacity(0.1))
                    .cornerRadius(8)

                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Carrier and number
                HStack(spacing: 4) {
                    if let carrier = transport.carrier {
                        Text(carrier)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    if let number = transport.transportNumber {
                        Text(number)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Route
                HStack(spacing: 4) {
                    Text(transport.departureLocation)
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(transport.arrivalLocation)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // Date and time
                Text(formatDateTime(transport.departureDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text(transport.durationFormatted)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)

                if let cost = transport.formattedCost {
                    Text(cost)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        TransportListView(journeyId: UUID())
    }
}
