import SwiftUI

struct ChecklistRow: View {
    let checklist: Checklist
    let progress: (checked: Int, total: Int)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)

                Text(checklist.name)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                // Progress bar
                ProgressView(value: progressPercentage)
                    .tint(progressColor)

                // Progress text
                Text("\(progress.checked)/\(progress.total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }

    private var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.checked) / Double(progress.total)
    }

    private var progressColor: Color {
        if progress.total == 0 {
            return .gray
        } else if progress.checked == progress.total {
            return .green
        } else if progressPercentage > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
}

#Preview {
    List {
        ChecklistRow(
            checklist: Checklist(journeyId: UUID(), name: "Packing"),
            progress: (checked: 5, total: 10)
        )
        ChecklistRow(
            checklist: Checklist(journeyId: UUID(), name: "Documents"),
            progress: (checked: 3, total: 3)
        )
        ChecklistRow(
            checklist: Checklist(journeyId: UUID(), name: "Before Departure"),
            progress: (checked: 0, total: 5)
        )
    }
}
