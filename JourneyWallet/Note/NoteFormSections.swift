import SwiftUI

struct NoteFormSections: View {
    @Bindable var viewModel: NoteFormViewModel
    let canMove: Bool
    let onAddLink: () -> Void
    let onEditLink: (NoteLink) -> Void
    let onAddDocument: () -> Void
    let onMove: () -> Void

    var body: some View {
        Form {
            Section(L("note.form.section.title")) {
                TextField(L("note.form.title_placeholder"), text: $viewModel.title)
                    .accessibilityIdentifier("note.title")
            }
            Section(L("note.form.section.content")) {
                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 200)
                    .accessibilityIdentifier("note.content")
            }
            if !viewModel.attachmentsLoaded {
                Section {
                    Button(L("note.retry_load"), action: viewModel.retryLoadingAttachments)
                        .accessibilityIdentifier("note.retry_load")
                } footer: {
                    Text(L("note.error.load"))
                }
            }
            Section(L("note.links.title")) {
                ForEach(viewModel.links) { link in
                    HStack {
                        Button { onEditLink(link) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(link.title)
                                Text(link.url)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("note.link.edit")
                        Button(role: .destructive) { viewModel.removeLink(id: link.id) } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(L("Delete"))
                        .accessibilityIdentifier("note.link.delete")
                    }
                }
                Button(action: onAddLink) {
                    Label(L("note.link.add"), systemImage: "plus")
                }
                .accessibilityIdentifier("note.link.add")
            }
            .disabled(!viewModel.attachmentsLoaded)
            Section {
                ForEach(viewModel.documents) { document in
                    HStack {
                        NoteDocumentRow(document: document)
                        Button(role: .destructive) { viewModel.removeDocument(id: document.id) } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(L("note.document.detach"))
                        .accessibilityIdentifier("note.document.detach")
                    }
                }
                Button(action: onAddDocument) {
                    Label(L("note.document.add"), systemImage: "paperclip")
                }
                .accessibilityIdentifier("note.document.add")
            } header: {
                Text(L("note.documents.title"))
            } footer: {
                Text(L("note.document.library_hint"))
            }
            .disabled(!viewModel.attachmentsLoaded)
            if canMove {
                Section {
                    Button(action: onMove) {
                        Label(L("common.move_to_journey"), systemImage: "folder")
                    }
                }
                .disabled(!viewModel.attachmentsLoaded)
            }
        }
    }
}
