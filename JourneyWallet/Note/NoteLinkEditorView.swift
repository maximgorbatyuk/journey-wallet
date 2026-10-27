import SwiftUI

struct NoteLinkEditorView: View {
    let link: NoteLink
    let onSave: (String, String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var url: String
    @State private var showValidationError = false

    init(link: NoteLink, onSave: @escaping (String, String) -> Bool) {
        self.link = link
        self.onSave = onSave
        _title = State(initialValue: link.title)
        _url = State(initialValue: link.url)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L("note.link.title")) {
                    TextField(L("note.link.title"), text: $title)
                        .accessibilityIdentifier("note.link.title")
                }
                Section(L("note.link.url")) {
                    TextField(L("note.link.url"), text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("note.link.url")
                }
            }
            .navigationTitle(L(link.title.isEmpty ? "note.link.add" : "note.link.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .accessibilityIdentifier("note.link.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save"), action: save)
                        .accessibilityIdentifier("note.link.save")
                }
            }
            .alert(L("note.form.validation.error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(L("note.link.validation"))
            }
        }
    }

    private func save() {
        if onSave(title, url) {
            dismiss()
        } else {
            showValidationError = true
        }
    }
}
