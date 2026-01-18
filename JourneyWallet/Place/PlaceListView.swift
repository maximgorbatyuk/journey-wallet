import SwiftUI

struct PlaceListView: View {

    let journeyId: UUID

    @State private var viewModel: PlaceListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: PlaceListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter section
            filterSection
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Summary bar
            if !viewModel.places.isEmpty {
                summaryBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredPlaces.isEmpty {
                emptyStateView
            } else {
                placeList
            }
        }
        .navigationTitle(L("place.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_place_button_clicked", properties: [
                        "screen": "place_list_screen"
                    ])
                    viewModel.showAddPlaceSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("place_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddPlaceSheet) {
            PlaceFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { place in
                    viewModel.addPlace(place)
                }
            )
        }
        .sheet(item: $viewModel.placeToEdit) { place in
            PlaceFormView(
                journeyId: journeyId,
                mode: .edit(place),
                onSave: { updatedPlace in
                    viewModel.updatePlace(updatedPlace)
                }
            )
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlaceFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        viewModel.applyFilters()
                    }
                }

                // Category filters
                Divider()
                    .frame(height: 20)

                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        if viewModel.selectedCategory == category {
                            viewModel.selectedCategory = nil
                        } else {
                            viewModel.selectedCategory = category
                        }
                        viewModel.applyFilters()
                    }
                }
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 16) {
            // Progress indicator
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("\(viewModel.visitedCount)/\(viewModel.places.count) \(L("place.summary.visited"))")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Progress percentage
            Text(String(format: "%.0f%%", viewModel.progressPercentage))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Place List

    private var placeList: some View {
        List {
            ForEach(viewModel.filteredPlaces) { place in
                PlaceListRow(
                    place: place,
                    onToggleVisited: {
                        viewModel.toggleVisited(place)
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.placeToEdit = place
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deletePlace(place)
                    } label: {
                        Label(L("Delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.placeToEdit = place
                    } label: {
                        Label(L("Edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        viewModel.toggleVisited(place)
                    } label: {
                        Label(
                            place.isVisited ? L("place.action.mark_unvisited") : L("place.action.mark_visited"),
                            systemImage: place.isVisited ? "xmark.circle" : "checkmark.circle"
                        )
                    }
                    .tint(place.isVisited ? .gray : .green)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "mappin.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("place.list.empty.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L("place.list.empty.message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddPlaceSheet = true
            }) {
                Label(L("place.list.add_first"), systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Place List Row

struct PlaceListRow: View {

    let place: PlaceToVisit
    let onToggleVisited: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Visited toggle button
            Button(action: onToggleVisited) {
                ZStack {
                    Circle()
                        .fill(place.isVisited ? Color.green.opacity(0.2) : place.category.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if place.isVisited {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 22))
                    } else {
                        Image(systemName: place.category.icon)
                            .foregroundColor(place.category.color)
                            .font(.system(size: 18))
                    }
                }
            }
            .buttonStyle(.plain)

            // Place info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(place.name)
                        .font(.headline)
                        .lineLimit(1)
                        .strikethrough(place.isVisited, color: .secondary)

                    if place.isPastPlannedDate {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    // Category badge
                    Text(place.category.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(place.category.color)
                        .cornerRadius(4)

                    // Planned date
                    if let plannedDate = place.plannedDate {
                        Text(formatDate(plannedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Address
                if let address = place.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .opacity(place.isVisited ? 0.7 : 1.0)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PlaceListView(journeyId: UUID())
    }
}
