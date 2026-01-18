import SwiftUI

struct CarRentalListView: View {

    let journeyId: UUID

    @State private var viewModel: CarRentalListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: CarRentalListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter section
            filterSection
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Summary bar
            if !viewModel.filteredCarRentals.isEmpty {
                summaryBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredCarRentals.isEmpty {
                emptyStateView
            } else {
                carRentalList
            }
        }
        .navigationTitle(L("car_rental.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_car_rental_button_clicked", properties: [
                        "screen": "car_rental_list_screen"
                    ])
                    viewModel.showAddCarRentalSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("car_rental_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddCarRentalSheet) {
            CarRentalFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { carRental in
                    viewModel.addCarRental(carRental)
                }
            )
        }
        .sheet(item: $viewModel.carRentalToEdit) { carRental in
            CarRentalFormView(
                journeyId: journeyId,
                mode: .edit(carRental),
                onSave: { updatedCarRental in
                    viewModel.updateCarRental(updatedCarRental)
                }
            )
        }
        .sheet(item: $viewModel.carRentalToView) { carRental in
            NavigationView {
                CarRentalDetailView(carRental: carRental, journeyId: journeyId)
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CarRentalFilter.allCases, id: \.self) { filter in
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
            // Total days
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(viewModel.totalDays) \(L("car_rental.days"))")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Total costs by currency
            if !viewModel.totalCostByCurrency.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.totalCostByCurrency.keys), id: \.self) { currency in
                        if let total = viewModel.totalCostByCurrency[currency] {
                            Text("\(currency.rawValue)\(total.formatted())")
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

    // MARK: - Car Rental List

    private var carRentalList: some View {
        List {
            ForEach(viewModel.filteredCarRentals) { carRental in
                CarRentalListRow(carRental: carRental)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.carRentalToView = carRental
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteCarRental(carRental)
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.carRentalToEdit = carRental
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

            Image(systemName: "car")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("car_rental.list.empty.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L("car_rental.list.empty.message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddCarRentalSheet = true
            }) {
                Label(L("car_rental.list.add_first"), systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Car Rental List Row

struct CarRentalListRow: View {

    let carRental: CarRental

    var body: some View {
        HStack(spacing: 12) {
            // Car icon with status color
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "car.fill")
                    .foregroundColor(statusColor)
                    .font(.system(size: 18))
            }

            // Rental info
            VStack(alignment: .leading, spacing: 4) {
                Text(carRental.company)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Dates
                    Text(formatDateRange())
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Days count
                    Text("(\(carRental.durationDays) \(L("car_rental.days_short")))")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }

                // Locations
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if carRental.isSameLocation {
                        Text(carRental.pickupLocation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("\(carRental.pickupLocation) → \(carRental.dropoffLocation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Cost and status
            VStack(alignment: .trailing, spacing: 4) {
                if let cost = carRental.cost, let currency = carRental.currency {
                    Text("\(currency.rawValue)\(cost.formatted())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                // Car type badge
                if let carType = carRental.carType, !carType.isEmpty {
                    Text(carType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
        if carRental.isActive {
            return L("car_rental.status.active")
        } else if carRental.isUpcoming {
            return L("car_rental.status.upcoming")
        } else {
            return L("car_rental.status.past")
        }
    }

    private var statusColor: Color {
        if carRental.isActive {
            return .green
        } else if carRental.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return "\(formatter.string(from: carRental.pickupDate)) - \(formatter.string(from: carRental.dropoffDate))"
    }
}
