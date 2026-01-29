import SwiftUI

struct PlaceDetailView: View {

    @State private var viewModel: PlaceDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showMoveSheet: Bool = false

    init(place: PlaceToVisit, journeyId: UUID) {
        _viewModel = State(initialValue: PlaceDetailViewModel(place: place, journeyId: journeyId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with status
                headerSection

                // Main info card
                mainInfoCard

                // Planned date card
                if viewModel.place.plannedDate != nil {
                    plannedDateCard
                }

                // URL card
                if let url = viewModel.place.url, !url.isEmpty {
                    urlCard(url: url)
                }

                // Notes card
                if let notes = viewModel.place.notes, !notes.isEmpty {
                    notesCard(notes: notes)
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(L("place.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label(L("Edit"), systemImage: "pencil")
                    }

                    Button {
                        viewModel.toggleVisited()
                    } label: {
                        Label(
                            viewModel.place.isVisited ? L("place.action.mark_unvisited") : L("place.action.mark_visited"),
                            systemImage: viewModel.place.isVisited ? "xmark.circle" : "checkmark.circle"
                        )
                    }

                    Button {
                        showMoveSheet = true
                    } label: {
                        Label(L("common.move_to_journey"), systemImage: "folder")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(L("Delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("place_detail_screen")
        }
        .sheet(isPresented: $showEditSheet) {
            PlaceFormView(
                journeyId: viewModel.journeyId,
                mode: .edit(viewModel.place),
                onSave: { updatedPlace in
                    viewModel.updatePlace(updatedPlace)
                },
                onMove: { newJourneyId in
                    if viewModel.moveToJourney(newJourneyId) {
                        dismiss()
                        return true
                    }
                    return false
                }
            )
        }
        .sheet(isPresented: $showMoveSheet) {
            MoveToJourneySheet(
                currentJourneyId: viewModel.journeyId,
                entityName: L("place.entity_name"),
                onMove: { newJourneyId in
                    if viewModel.moveToJourney(newJourneyId) {
                        dismiss()
                    }
                }
            )
        }
        .alert(L("place.detail.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                if viewModel.deletePlace() {
                    dismiss()
                }
            }
        } message: {
            Text(L("place.detail.delete_confirm.message"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Place icon
            ZStack {
                Circle()
                    .fill(viewModel.place.isVisited ? Color.green.opacity(0.2) : viewModel.place.category.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                if viewModel.place.isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: viewModel.place.category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(viewModel.place.category.color)
                }
            }

            // Place name
            Text(viewModel.place.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Status badge
            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(statusColor)
                .cornerRadius(16)
        }
        .padding(.vertical, 20)
    }

    private var statusText: String {
        if viewModel.place.isVisited {
            return L("place.status.visited")
        } else {
            return L("place.status.not_visited")
        }
    }

    private var statusColor: Color {
        viewModel.place.isVisited ? .green : .orange
    }

    // MARK: - Main Info Card

    private var mainInfoCard: some View {
        VStack(spacing: 16) {
            // Category
            HStack(spacing: 12) {
                Image(systemName: viewModel.place.category.icon)
                    .foregroundColor(viewModel.place.category.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("place.detail.category"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.place.category.displayName)
                        .font(.body)
                }

                Spacer()
            }

            // Address
            if let address = viewModel.place.address, !address.isEmpty {
                Divider()

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("place.detail.address"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(address)
                            .font(.body)
                    }

                    Spacer()

                    // Open in Maps button
                    if !isURL(address) {
                        Button {
                            openInMaps(address)
                        } label: {
                            Image(systemName: "map.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Planned Date Card

    private var plannedDateCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("place.detail.planned_date"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let date = viewModel.place.plannedDate {
                        Text(formatDate(date))
                            .font(.headline)
                    }
                }

                Spacer()

                // Past date warning
                if viewModel.place.isPastPlannedDate {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - URL Card

    private func urlCard(url: String) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("place.detail.url"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(urlDisplayText(url))
                        .font(.body)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }

                Spacer()

                // Open URL button
                Button {
                    openURLString(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                }

                // Copy button
                CopyButton(text: url, iconSize: 16, padding: 8, cornerRadius: 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text(L("place.detail.notes"))
                    .font(.headline)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Toggle visited button
            Button(action: {
                viewModel.toggleVisited()
            }) {
                HStack {
                    Image(systemName: viewModel.place.isVisited ? "xmark.circle" : "checkmark.circle.fill")
                    Text(viewModel.place.isVisited ? L("place.action.mark_unvisited") : L("place.action.mark_visited"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.place.isVisited ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Open in Maps button (if address exists and is not URL)
            if let address = viewModel.place.address, !address.isEmpty, !isURL(address) {
                Button(action: {
                    openInMaps(address)
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text(L("place.detail.action.map"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            // Open URL button (if URL exists)
            if let url = viewModel.place.url, !url.isEmpty {
                Button(action: {
                    openURLString(url)
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text(L("place.detail.action.open_link"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func isURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    private func openURLString(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return }
        openURL(url)
    }

    private func urlDisplayText(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host ?? urlString
    }

    private func openInMaps(_ address: String) {
        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            openURL(url)
        }
    }
}
