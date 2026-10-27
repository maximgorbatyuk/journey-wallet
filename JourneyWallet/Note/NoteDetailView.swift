import SwiftUI

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var viewModel: NoteDetailViewModel
    @State private var noteToEdit: Note?
    @State private var documentToPreview: Document?

    init(noteId: UUID) {
        _viewModel = State(initialValue: NoteDetailViewModel(noteId: noteId))
    }

    var body: some View {
        Group {
            if let note = viewModel.note {
                Form {
                    if !note.content.isEmpty {
                        Section {
                            Text(note.content)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .accessibilityIdentifier("note.detail.content")
                        }
                    }
                    if !viewModel.links.isEmpty {
                        Section(L("note.links.title")) {
                            ForEach(viewModel.links) { link in
                                Button { openLink(link) } label: {
                                    Label(link.title, systemImage: "link")
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .accessibilityIdentifier("note.link.open")
                            }
                        }
                    }
                    if !viewModel.documents.isEmpty {
                        Section(L("note.documents.title")) {
                            ForEach(viewModel.documents) { document in
                                Button {
                                    if viewModel.canPreview(document) {
                                        documentToPreview = document
                                    }
                                } label: {
                                    NoteDocumentRow(document: document)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("note.document.open")
                                .accessibilityLabel(document.displayName)
                            }
                        }
                    }
                }
                .navigationTitle(note.title.isEmpty ? L("note.untitled") : note.title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(L("Edit")) { noteToEdit = note }
                            .accessibilityIdentifier("note.edit")
                    }
                }
            } else {
                ContentUnavailableView(L("note.detail.unavailable"), systemImage: "note.text")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.reload()
            AnalyticsService.shared.trackScreen("note_detail_screen")
        }
        .sheet(item: $noteToEdit, onDismiss: didDismissEditor) { note in
            NoteFormView(
                journeyId: note.journeyId,
                mode: .edit(note),
                onSave: { _ in viewModel.reload() },
                onMove: viewModel.moveNote
            )
        }
        .sheet(item: $documentToPreview, onDismiss: viewModel.reload) { document in
            DocumentPreviewView(document: document, journeyId: document.journeyId)
        }
        .alert(L("note.form.validation.error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                }
            }
        )) {
            Button(L("OK"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func didDismissEditor() {
        if viewModel.hasMoved {
            dismiss()
        } else {
            viewModel.reload()
        }
    }

    private func openLink(_ link: NoteLink) {
        guard let url = NoteLinkURL.normalized(link.url) else {
            viewModel.errorMessage = L("note.error.open_link")
            return
        }
        openURL(url) { accepted in
            if !accepted {
                viewModel.errorMessage = L("note.error.open_link")
            }
        }
    }
}
