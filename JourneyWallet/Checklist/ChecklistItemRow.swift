import SwiftUI

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.statusIcon)
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? .green : .secondary)

                Text(item.name)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        ChecklistItemRow(
            item: ChecklistItem(checklistId: UUID(), name: "Pack passport", isChecked: true),
            onToggle: {}
        )
        ChecklistItemRow(
            item: ChecklistItem(checklistId: UUID(), name: "Book airport transfer"),
            onToggle: {}
        )
    }
}
