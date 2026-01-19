import SwiftUI

struct DocumentNameEntryView: View {

    let fileName: String
    let filePath: String
    let fileSize: Int64
    let nameRequired: Bool
    let onSave: (String?) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var documentName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    /// Check if the save button should be enabled
    private var canSave: Bool {
        if nameRequired {
            return !documentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    // File info (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.orange)
                            Text(fileName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Text(filePath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        Text(formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L("document.name_entry.file_info"))
                }

                Section {
                    TextField(L("document.name_entry.name_placeholder"), text: $documentName)
                        .focused($isNameFieldFocused)
                        .textContentType(.name)
                } header: {
                    if nameRequired {
                        Text(L("document.name_entry.name_section_required"))
                    } else {
                        Text(L("document.name_entry.name_section"))
                    }
                } footer: {
                    if nameRequired {
                        Text(L("document.name_entry.name_required_hint"))
                    } else {
                        Text(L("document.name_entry.name_hint"))
                    }
                }
            }
            .navigationTitle(L("document.name_entry.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        // Pass nil if name is empty, otherwise pass the trimmed name
                        let trimmedName = documentName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmedName.isEmpty ? nil : trimmedName)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }

    private var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

#Preview {
    DocumentNameEntryView(
        fileName: "boarding_pass.pdf",
        filePath: "/Users/example/Downloads/boarding_pass.pdf",
        fileSize: 245_000,
        nameRequired: false,
        onSave: { _ in },
        onCancel: {}
    )
}
