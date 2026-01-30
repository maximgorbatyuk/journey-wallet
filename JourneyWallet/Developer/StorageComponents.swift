import SwiftUI

struct StorageStatsSection: View {
    let stats: StorageStats

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(L("developer.document_storage.stats.title"))
                    .font(.headline)

                Text(stats.formattedTotalSize)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text(String(format: L("developer.document_storage.stats.files_folders"), stats.fileCount, stats.folderCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct FolderRow: View {
    let item: StorageItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)

                if let count = item.fileCount {
                    Text("\(count) \(L("developer.document_storage.stats.files")) • \(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FileRow: View {
    let item: StorageItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(item.iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(item.fileType) • \(item.formattedSize) • \(formatDate(item.modificationDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .textSelection(.enabled)
        }
    }
}
