import SwiftUI

struct IdeaDetailView: View {

    @State private var viewModel: IdeaDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showMoveSheet: Bool = false
    @State private var showShareSheet: Bool = false

    init(idea: Idea, journeyId: UUID) {
        _viewModel = State(initialValue: IdeaDetailViewModel(idea: idea, journeyId: journeyId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with status
                headerSection

                // Description card
                if let description = viewModel.idea.description, !description.isEmpty {
                    descriptionCard(description: description)
                }

                // URL card
                if let url = viewModel.idea.url, !url.isEmpty {
                    urlCard(url: url)
                }

                // Actions
                actionsSection

                // Timestamps
                timestampsSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(L("idea.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label(L("idea.action.edit"), systemImage: "pencil")
                    }

                    Button {
                        viewModel.toggleDone()
                    } label: {
                        Label(
                            viewModel.idea.isDone ? L("idea.action.mark_not_done") : L("idea.action.mark_done"),
                            systemImage: viewModel.idea.isDone ? "circle" : "checkmark.circle"
                        )
                    }

                    Button {
                        showMoveSheet = true
                    } label: {
                        Label(L("idea.action.move"), systemImage: "folder")
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Label(L("idea.action.share"), systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(L("idea.action.delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("idea_detail_screen")
        }
        .sheet(isPresented: $showEditSheet) {
            IdeaFormView(
                journeyId: viewModel.journeyId,
                mode: .edit(viewModel.idea),
                onSave: { updatedIdea in
                    viewModel.updateIdea(updatedIdea)
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
                entityName: L("idea.detail.title"),
                onMove: { newJourneyId in
                    if viewModel.moveToJourney(newJourneyId) {
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [viewModel.idea.shareText])
        }
        .alert(L("idea.delete.confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                if viewModel.deleteIdea() {
                    analytics.trackEvent("idea_deleted", properties: ["idea_id": viewModel.idea.id.uuidString])
                    dismiss()
                }
            }
        } message: {
            Text(L("idea.delete.confirm.message"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Idea icon
            ZStack {
                Circle()
                    .fill(viewModel.idea.isDone ? Color.green.opacity(0.2) : Color.yellow.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: viewModel.idea.isDone ? "checkmark.circle.fill" : "lightbulb.fill")
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.idea.isDone ? .green : .yellow)
            }

            // Idea title
            Text(viewModel.idea.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .strikethrough(viewModel.idea.isDone, color: .secondary)

            // Status badge
            Text(viewModel.idea.isDone ? L("idea.detail.status.done") : L("idea.detail.status.not_done"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(viewModel.idea.isDone ? Color.green : Color.orange)
                .cornerRadius(16)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Description Card

    private func descriptionCard(description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.yellow)
                Text(L("idea.detail.section.description"))
                    .font(.headline)
            }

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text(L("idea.detail.section.link"))
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

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: 0) {
            // Mark as Done button
            compactActionButton(
                icon: viewModel.idea.isDone ? "circle" : "checkmark.circle.fill",
                label: viewModel.idea.isDone ? L("idea.action.undo") : L("idea.action.done"),
                color: viewModel.idea.isDone ? .gray : .green
            ) {
                viewModel.toggleDone()
                analytics.trackEvent("idea_marked_done", properties: [
                    "idea_id": viewModel.idea.id.uuidString,
                    "is_done": String(!viewModel.idea.isDone)
                ])
            }

            // Open URL button (if URL exists)
            if let url = viewModel.idea.url, !url.isEmpty {
                compactActionButton(
                    icon: "link",
                    label: L("idea.action.open"),
                    color: .blue
                ) {
                    openURLString(url)
                    analytics.trackEvent("idea_url_opened", properties: ["idea_id": viewModel.idea.id.uuidString])
                }
            }

            // Share button
            compactActionButton(
                icon: "square.and.arrow.up",
                label: L("idea.action.share_short"),
                color: .orange
            ) {
                showShareSheet = true
                analytics.trackEvent("idea_shared", properties: ["idea_id": viewModel.idea.id.uuidString])
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.top, 8)
    }

    private func compactActionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timestamps Section

    private var timestampsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L("idea.detail.created"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDate(viewModel.idea.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(L("idea.detail.updated"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDate(viewModel.idea.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.top, 12)
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}
