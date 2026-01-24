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

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)

                    // Show last modified only for checked items
                    if item.isChecked {
                        Text(lastModifiedText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var lastModifiedText: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: item.updatedAt, to: now)
        let days = components.day ?? 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: item.updatedAt)

        if days == 0 {
            return L("common.today") + " (\(dateString))"
        } else if days == 1 {
            return L("common.yesterday") + " (\(dateString))"
        } else {
            return String(format: L("common.days_ago"), days) + " (\(dateString))"
        }
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
