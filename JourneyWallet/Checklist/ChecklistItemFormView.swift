import SwiftUI

struct ChecklistItemFormView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String) -> Void
    let existingItem: ChecklistItem?

    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool

    init(existingItem: ChecklistItem? = nil, onSave: @escaping (String) -> Void) {
        self.existingItem = existingItem
        self.onSave = onSave
        _name = State(initialValue: existingItem?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("checklist.items.name.placeholder"), text: $name)
                        .focused($isNameFocused)
                } header: {
                    Text(L("checklist.items.name"))
                }
            }
            .navigationTitle(existingItem == nil ? L("checklist.items.add") : L("checklist.items.edit"))
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
    ChecklistItemFormView { name in
        print("Saved: \(name)")
    }
}
