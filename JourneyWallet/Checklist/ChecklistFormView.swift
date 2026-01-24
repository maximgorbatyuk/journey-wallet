import SwiftUI

struct ChecklistFormView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String) -> Void
    let existingChecklist: Checklist?

    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool

    init(existingChecklist: Checklist? = nil, onSave: @escaping (String) -> Void) {
        self.existingChecklist = existingChecklist
        self.onSave = onSave
        _name = State(initialValue: existingChecklist?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("checklists.name.placeholder"), text: $name)
                        .focused($isNameFocused)
                } header: {
                    Text(L("checklists.name"))
                }
            }
            .navigationTitle(existingChecklist == nil ? L("checklists.add") : L("checklists.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
}

#Preview {
    ChecklistFormView { name in
        print("Saved: \(name)")
    }
}
