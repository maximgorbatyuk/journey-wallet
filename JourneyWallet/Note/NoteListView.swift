import SwiftUI

struct NoteListView: View {

    let journeyId: UUID

    @State private var viewModel: NoteListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: NoteListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            if !viewModel.notes.isEmpty {
                summaryBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.notes.isEmpty {
                emptyStateView
            } else {
                noteList
            }
        }
        .navigationTitle(L("note.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_note_button_clicked", properties: [
                        "screen": "note_list_screen"
                    ])
                    viewModel.showAddNoteSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("note_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddNoteSheet) {
            NoteFormView(
                journeyId: journeyId,
                mode: .add,
                onSave: { note in
                    viewModel.addNote(note)
                }
            )
        }
        .sheet(item: $viewModel.noteToEdit) { note in
            NoteFormView(
                journeyId: journeyId,
                mode: .edit(note),
                onSave: { updatedNote in
                    viewModel.updateNote(updatedNote)
                }
            )
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack {
            Label("\(viewModel.totalCount) \(L("note.summary.notes"))", systemImage: "note.text")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Note List

    private var noteList: some View {
        List {
            ForEach(viewModel.notes) { note in
                NoteListRow(note: note)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.noteToEdit = note
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteNote(note)
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.noteToEdit = note
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

            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("note.list.empty.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L("note.list.empty.message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddNoteSheet = true
            }) {
                Label(L("note.list.add_first"), systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Note List Row

struct NoteListRow: View {

    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            // Note icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
            }

            // Note info
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? L("note.untitled") : note.title)
                    .font(.headline)
                    .lineLimit(1)

                if !note.content.isEmpty {
                    Text(note.contentPreview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(formatDate(note.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        NoteListView(journeyId: UUID())
    }
}
