import SwiftUI

struct HotelListView: View {

    let journeyId: UUID

    @State private var viewModel: HotelListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: HotelListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter section
            filterSection
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Summary bar
            if !viewModel.filteredHotels.isEmpty {
                summaryBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredHotels.isEmpty {
                emptyStateView
            } else {
                hotelList
            }
        }
        .navigationTitle(L("hotel.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_hotel_button_clicked", properties: [
                        "screen": "hotel_list_screen"
                    ])
                    viewModel.showAddHotelSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("hotel_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddHotelSheet) {
            HotelFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { hotel in
                    viewModel.addHotel(hotel)
                }
            )
        }
        .sheet(item: $viewModel.hotelToEdit) { hotel in
            HotelFormView(
                journeyId: journeyId,
                mode: .edit(hotel),
                onSave: { updatedHotel in
                    viewModel.updateHotel(updatedHotel)
                }
            )
        }
        .sheet(item: $viewModel.hotelToView) { hotel in
            NavigationView {
                HotelDetailView(hotel: hotel, journeyId: journeyId)
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HotelFilter.allCases, id: \.self) { filter in
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

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 16) {
            // Total nights
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(viewModel.totalNights) \(L("hotel.nights"))")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Total costs by currency
            if !viewModel.totalCostByCurrency.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.totalCostByCurrency.keys), id: \.self) { currency in
                        if let total = viewModel.totalCostByCurrency[currency] {
                            Text("\(currency.symbol)\(total.formatted())")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Hotel List

    private var hotelList: some View {
        List {
            ForEach(viewModel.filteredHotels) { hotel in
                HotelListRow(hotel: hotel)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.hotelToView = hotel
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteHotel(hotel)
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.hotelToEdit = hotel
                        } label: {
                            Label(L("Edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("hotel.list.empty.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L("hotel.list.empty.message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddHotelSheet = true
            }) {
                Label(L("hotel.list.add_first"), systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Hotel List Row

struct HotelListRow: View {

    let hotel: Hotel

    var body: some View {
        HStack(spacing: 12) {
            // Hotel icon with status color
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "building.2.fill")
                    .foregroundColor(statusColor)
                    .font(.system(size: 18))
            }

            // Hotel info
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Dates
                    Text(formatDateRange())
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Nights count
                    Text("(\(hotel.nightsCount) \(L("hotel.nights_short")))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }

                // Address
                if !hotel.address.isEmpty {
                    Text(hotel.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Cost and status
            VStack(alignment: .trailing, spacing: 4) {
                if let cost = hotel.cost, let currency = hotel.currency {
                    Text("\(currency.symbol)\(cost.formatted())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                // Status badge
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        if hotel.isActive {
            return L("hotel.status.active")
        } else if hotel.isUpcoming {
            return L("hotel.status.upcoming")
        } else {
            return L("hotel.status.past")
        }
    }

    private var statusColor: Color {
        if hotel.isActive {
            return .green
        } else if hotel.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return "\(formatter.string(from: hotel.checkInDate)) - \(formatter.string(from: hotel.checkOutDate))"
    }
}
