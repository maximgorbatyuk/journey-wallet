import SwiftUI

enum NoteFormMode {
    case add
    case edit(Note)

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }

    var existingNote: Note? {
        if case let .edit(note) = self {
            return note
        }
        return nil
    }
}

struct NoteFormView: View {
    let journeyId: UUID
    let mode: NoteFormMode
    let onSave: (Note) -> Void
    let onMove: ((UUID) -> Bool)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NoteFormViewModel
    @State private var linkToEdit: NoteLink?
    @State private var showDocumentOptions = false
    @State private var showExistingDocuments = false
    @State private var showImport = false
    @State private var showMoveSheet = false
    @State private var showMoveWarning = false

    init(
        journeyId: UUID,
        mode: NoteFormMode,
        onSave: @escaping (Note) -> Void = { _ in },
        onMove: ((UUID) -> Bool)? = nil
    ) {
        self.journeyId = journeyId
        self.mode = mode
        self.onSave = onSave
        self.onMove = onMove
        _viewModel = State(initialValue: NoteFormViewModel(journeyId: journeyId, mode: mode))
    }

    var body: some View {
        NavigationStack {
            NoteFormSections(
                viewModel: viewModel,
                canMove: mode.isEditing && onMove != nil,
                onAddLink: addLink,
                onEditLink: { linkToEdit = $0 },
                onAddDocument: { showDocumentOptions = true },
                onMove: requestMove
            )
            .navigationTitle(L(mode.isEditing ? "note.form.edit_title" : "note.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .accessibilityIdentifier("note.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save"), action: saveNote)
                        .fontWeight(.semibold)
                        .disabled(!viewModel.attachmentsLoaded)
                        .accessibilityIdentifier("note.save")
                }
            }
            .onAppear { AnalyticsService.shared.trackScreen("note_form_screen") }
            .sheet(item: $linkToEdit) { link in
                NoteLinkEditorView(link: link) { title, url in
                    viewModel.upsertLink(id: link.id, title: title, url: url)
                }
            }
            .sheet(isPresented: $showExistingDocuments) {
                NoteDocumentSelectionView(
                    documents: viewModel.availableDocuments,
                    selectedIds: Set(viewModel.documents.map(\.id))
                ) {
                    viewModel.selectDocuments(ids: $0)
                }
            }
            .sheet(isPresented: $showImport) {
                DocumentPickerView(
                    journeyId: journeyId,
                    onImported: viewModel.attachImportedDocuments,
                    onComplete: { _ in }
                )
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveToJourneySheet(currentJourneyId: journeyId, entityName: L("note.entity_name")) { newJourneyId in
                    if onMove?(newJourneyId) == true {
                        dismiss()
                    } else {
                        viewModel.errorMessage = L("note.error.move")
                    }
                }
            }
            .confirmationDialog(L("note.documents.title"), isPresented: $showDocumentOptions) {
                Button(L("note.document.existing")) {
                    viewModel.refreshAvailableDocuments()
                    showExistingDocuments = true
                }
                .accessibilityIdentifier("note.document.existing")
                Button(L("note.document.new")) { showImport = true }
                    .accessibilityIdentifier("note.document.new")
                Button(L("Cancel"), role: .cancel) {}
            }
            .alert(L("common.move_to_journey"), isPresented: $showMoveWarning) {
                Button(L("Cancel"), role: .cancel) {}
                Button(L("note.move.continue")) { showMoveSheet = true }
            } message: {
                Text(L("note.move.detach_warning"))
            }
            .alert(L("Error"), isPresented: Binding(
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
    }

    private func addLink() {
        linkToEdit = NoteLink(noteId: viewModel.noteId, title: "", url: "", sortOrder: viewModel.links.count)
    }

    private func requestMove() {
        if viewModel.documents.isEmpty {
            showMoveSheet = true
        } else {
            showMoveWarning = true
        }
    }

    private func saveNote() {
        guard let note = viewModel.save() else { return }
        AnalyticsService.shared.trackEvent(mode.isEditing ? "note_updated" : "note_created", properties: [
            "note_id": note.id.uuidString, "journey_id": journeyId.uuidString
        ])
        onSave(note)
        dismiss()
    }
}
