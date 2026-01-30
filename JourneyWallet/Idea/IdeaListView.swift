import SwiftUI

struct IdeaListView: View {

    let journeyId: UUID

    @State private var viewModel: IdeaListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: IdeaListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            if !viewModel.ideas.isEmpty {
                summaryBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.ideas.isEmpty {
                emptyStateView
            } else {
                ideaList
            }
        }
        .navigationTitle(L("idea.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_idea_button_clicked", properties: [
                        "screen": "idea_list_screen"
                    ])
                    viewModel.showAddIdeaSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("idea_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddIdeaSheet) {
            IdeaFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { idea in
                    viewModel.addIdea(idea)
                }
            )
        }
        .sheet(item: $viewModel.ideaToEdit) { idea in
            IdeaFormView(
                journeyId: journeyId,
                mode: .edit(idea),
                onSave: { updatedIdea in
                    viewModel.updateIdea(updatedIdea)
                },
                onMove: { newJourneyId in
                    viewModel.moveToJourney(idea: idea, newJourneyId: newJourneyId)
                }
            )
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
                Text("\(viewModel.doneCount)/\(viewModel.totalCount) \(L("idea.list.section.done").lowercased())")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            // Progress percentage
            Text(String(format: "%.0f%%", viewModel.progressPercentage))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Idea List

    private var ideaList: some View {
        List {
            // Pending ideas
            if !viewModel.pendingIdeas.isEmpty {
                ForEach(viewModel.pendingIdeas) { idea in
                    ideaRow(idea: idea)
                }
            }

            // Done ideas
            if !viewModel.doneIdeas.isEmpty {
                Section {
                    ForEach(viewModel.doneIdeas) { idea in
                        ideaRow(idea: idea)
                    }
                } header: {
                    Text(L("idea.list.section.done"))
                }
            }
        }
        .listStyle(.plain)
    }

    private func ideaRow(idea: Idea) -> some View {
        NavigationLink(destination: IdeaDetailView(idea: idea, journeyId: journeyId)) {
            IdeaListRow(
                idea: idea,
                onToggleDone: {
                    viewModel.toggleDone(idea)
                }
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.deleteIdea(idea)
            } label: {
                Label(L("Delete"), systemImage: "trash")
            }

            Button {
                viewModel.ideaToEdit = idea
            } label: {
                Label(L("Edit"), systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.toggleDone(idea)
            } label: {
                Label(
                    idea.isDone ? L("idea.action.mark_not_done") : L("idea.action.mark_done"),
                    systemImage: idea.isDone ? "circle" : "checkmark.circle"
                )
            }
            .tint(idea.isDone ? .gray : .green)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("idea.list.empty.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L("idea.list.empty.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddIdeaSheet = true
            }) {
                Label(L("idea.list.empty.button"), systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Idea List Row

struct IdeaListRow: View {

    let idea: Idea
    let onToggleDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Done toggle button
            Button(action: onToggleDone) {
                ZStack {
                    Circle()
                        .fill(idea.isDone ? Color.green.opacity(0.2) : Color.yellow.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if idea.isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 22))
                    } else {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 18))
                    }
                }
            }
            .buttonStyle(.plain)

            // Idea info
            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.headline)
                    .lineLimit(1)
                    .strikethrough(idea.isDone, color: .secondary)

                if let description = idea.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // URL field
                if let url = idea.url, !url.isEmpty {
                    HStack(spacing: 8) {
                        Button(action: {
                            openURL(url)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text(urlDisplayText(url))
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)

                        CopyButton(text: url, iconSize: 12, padding: 4, cornerRadius: 4)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(idea.isDone ? 0.7 : 1.0)
    }

    private func openURL(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return }
        UIApplication.shared.open(url)
    }

    private func urlDisplayText(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host ?? urlString
    }
}

#Preview {
    NavigationStack {
        IdeaListView(journeyId: UUID())
    }
}
