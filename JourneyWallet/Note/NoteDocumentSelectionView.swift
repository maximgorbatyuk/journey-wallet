import SwiftUI

struct NoteDocumentSelectionView: View {
    let documents: [Document]
    let onSave: (Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIds: Set<UUID>

    init(documents: [Document], selectedIds: Set<UUID>, onSave: @escaping (Set<UUID>) -> Void) {
        self.documents = documents
        self.onSave = onSave
        _selectedIds = State(initialValue: selectedIds)
    }

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    ContentUnavailableView(L("note.document.empty"), systemImage: "doc")
                } else {
                    List(documents) { document in
                        Button {
                            toggle(document.id)
                        } label: {
                            HStack {
                                NoteDocumentRow(document: document)
                                if selectedIds.contains(document.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("note.document.select")
                        .accessibilityLabel(document.displayName)
                        .accessibilityAddTraits(selectedIds.contains(document.id) ? .isSelected : [])
                    }
                }
            }
            .navigationTitle(L("note.document.choose"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        onSave(selectedIds)
                        dismiss()
                    }
                    .accessibilityIdentifier("note.document.choose.save")
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}
