import Foundation
import SwiftUI
import os
import UniformTypeIdentifiers

/// Service for browsing raw document storage (developer debugging)
final class DocumentStorageService {

    static let shared = DocumentStorageService()

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "DocumentStorageService")

    /// Returns root documents directory
    var rootDirectory: URL {
        AppGroupContainer.documentsURL
    }

    /// Get all items (files and folders) in a directory
    func getContents(of directory: URL) -> [StorageItem] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .creationDateKey
                ],
                options: [.skipsHiddenFiles]
            )

            return contents.compactMap { url in
                let resourceValues = try? url.resourceValues(forKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .creationDateKey
                ])

                guard let isDirectory = resourceValues?.isDirectory else { return nil }
                let size = resourceValues?.fileSize ?? 0
                let modificationDate = resourceValues?.contentModificationDate ?? Date()

                var fileCount: Int? = nil
                if isDirectory {
                    fileCount = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).count
                }

                return StorageItem(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: isDirectory,
                    size: Int64(size),
                    modificationDate: modificationDate,
                    fileCount: fileCount
                )
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            logger.error("Failed to get contents of directory: \(directory.path), error: \(error.localizedDescription)")
            return []
        }
    }

    /// Get storage statistics
    func getStorageStats() -> StorageStats {
        let directories = getContents(of: rootDirectory).filter { $0.isDirectory }
        let files = getContents(of: rootDirectory).filter { !$0.isDirectory }

        var totalSize = Int64(0)
        var fileCount = 0

        for directory in directories {
            if let dirSize = calculateDirectorySize(at: directory.url) {
                totalSize += dirSize
            }
            fileCount += directory.fileCount ?? 0
        }

        for file in files {
            totalSize += file.size
            fileCount += 1
        }

        return StorageStats(
            totalSize: totalSize,
            fileCount: fileCount,
            folderCount: directories.count
        )
    }

    /// Delete a file or directory
    func deleteItem(at url: URL) -> Bool {
        do {
            try fileManager.removeItem(at: url)
            logger.info("Deleted item at: \(url.path)")
            return true
        } catch {
            logger.error("Failed to delete item at \(url.path): \(error.localizedDescription)")
            return false
        }
    }

    /// Get file attributes
    func getFileAttributes(at url: URL) -> FileAttributes? {
        let resourceValues = try? url.resourceValues(forKeys: [
            .nameKey,
            .typeIdentifierKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])

        guard let name = resourceValues?.name,
              let typeIdentifier = resourceValues?.typeIdentifier else { return nil }

        let typeName = UTType(typeIdentifier)?.localizedDescription ?? typeIdentifier

        return FileAttributes(
            name: name,
            path: url.path,
            size: resourceValues?.fileSize ?? 0,
            type: typeName,
            creationDate: resourceValues?.creationDate,
            modificationDate: resourceValues?.contentModificationDate
        )
    }

    /// Calculate total size of a directory
    private func calculateDirectorySize(at url: URL) -> Int64? {
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
        var totalSize = Int64(0)

        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues?.fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }
}

/// Storage item (file or folder)
struct StorageItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let fileCount: Int?

    var icon: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()

        switch ext {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "chart.bar.doc.horizontal.fill"
        case "txt", "text": return "doc.plaintext.fill"
        case "zip", "rar": return "archivebox.fill"
        default: return "doc.fill"
        }
    }

    var iconColor: Color {
        if isDirectory { return .blue }
        let ext = (name as NSString).pathExtension.lowercased()

        switch ext {
        case "pdf": return .red
        case "jpg", "jpeg", "png", "gif", "heic": return .green
        case "doc", "docx": return .blue
        case "xls", "xlsx": return .green
        case "txt", "text": return .gray
        case "zip", "rar": return .orange
        default: return .gray
        }
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileType: String {
        if isDirectory { return "Folder" }
        let ext = (name as NSString).pathExtension.uppercased()
        return ext.isEmpty ? "Unknown" : "\(ext) File"
    }
}

/// Storage statistics
struct StorageStats {
    let totalSize: Int64
    let fileCount: Int
    let folderCount: Int

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

/// File attributes
struct FileAttributes {
    let name: String
    let path: String
    let size: Int
    let type: String
    let creationDate: Date?
    let modificationDate: Date?
}
