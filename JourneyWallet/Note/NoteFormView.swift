import SwiftUI

enum NoteFormMode {
    case add
    case edit(Note)

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingNote: Note? {
        if case .edit(let note) = self { return note }
        return nil
    }
}

struct NoteFormView: View {

    let journeyId: UUID
    let mode: NoteFormMode
    let onSave: (Note) -> Void
    let onMove: ((UUID) -> Bool)?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form fields
    @State private var title: String = ""
    @State private var content: String = ""

    // Validation
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    // Move sheet
    @State private var showMoveSheet: Bool = false

    init(journeyId: UUID, mode: NoteFormMode, onSave: @escaping (Note) -> Void, onMove: ((UUID) -> Bool)? = nil) {
        self.journeyId = journeyId
        self.mode = mode
        self.onSave = onSave
        self.onMove = onMove
    }

    var body: some View {
        NavigationView {
            Form {
                // Title section
                Section {
                    TextField(L("note.form.title_placeholder"), text: $title)
                } header: {
                    Text(L("note.form.section.title"))
                }

                // Content section
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                } header: {
                    Text(L("note.form.section.content"))
                }

                if mode.isEditing, onMove != nil {
                    Section {
                        Button {
                            showMoveSheet = true
                        } label: {
                            Label(L("common.move_to_journey"), systemImage: "folder")
                        }
                    }
                }
            }
            .navigationTitle(mode.isEditing ? L("note.form.edit_title") : L("note.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                analytics.trackScreen("note_form_screen")
                loadExistingData()
            }
            .alert(L("note.form.validation.error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveToJourneySheet(
                    currentJourneyId: journeyId,
                    entityName: L("note.entity_name"),
                    onMove: { newJourneyId in
                        if onMove?(newJourneyId) == true {
                            dismiss()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Private Methods

    private func loadExistingData() {
        if let note = mode.existingNote {
            title = note.title
            content = note.content
        }
    }

    private func saveNote() {
        // Validate - at least title or content should be non-empty
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTitle.isEmpty && trimmedContent.isEmpty {
            validationMessage = L("note.form.validation.empty")
            showValidationError = true
            return
        }

        let note: Note

        if let existingNote = mode.existingNote {
            // Update existing note
            note = Note(
                id: existingNote.id,
                journeyId: journeyId,
                title: trimmedTitle,
                content: trimmedContent,
                createdAt: existingNote.createdAt,
                updatedAt: Date()
            )
            analytics.trackEvent("note_updated", properties: ["note_id": existingNote.id.uuidString])
        } else {
            // Create new note
            note = Note(
                journeyId: journeyId,
                title: trimmedTitle,
                content: trimmedContent
            )
            analytics.trackEvent("note_created", properties: ["journey_id": journeyId.uuidString])
        }

        onSave(note)
        dismiss()
    }
}

#Preview {
    NoteFormView(
        journeyId: UUID(),
        mode: .add,
        onSave: { _ in },
        onMove: nil
    )
}
