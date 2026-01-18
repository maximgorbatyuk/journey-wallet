import Foundation
import os

class DocumentService {

    static let shared = DocumentService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "DocumentService")
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Directory Management

    /// Returns the documents directory for storing journey documents
    func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent("JourneyDocuments", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            do {
                try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
                logger.info("Created JourneyDocuments directory")
            } catch {
                logger.error("Failed to create JourneyDocuments directory: \(error)")
            }
        }

        return documentsDirectory
    }

    /// Returns the directory for a specific journey's documents
    func getJourneyDocumentsDirectory(journeyId: UUID) -> URL {
        let journeyDirectory = getDocumentsDirectory().appendingPathComponent(journeyId.uuidString, isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: journeyDirectory.path) {
            do {
                try fileManager.createDirectory(at: journeyDirectory, withIntermediateDirectories: true)
                logger.info("Created directory for journey: \(journeyId)")
            } catch {
                logger.error("Failed to create journey directory: \(error)")
            }
        }

        return journeyDirectory
    }

    // MARK: - File Operations

    /// Saves document data to the file system and returns the file URL
    func saveDocument(data: Data, fileName: String, journeyId: UUID) -> URL? {
        let directory = getJourneyDocumentsDirectory(journeyId: journeyId)
        let uniqueFileName = generateUniqueFileName(fileName, in: directory)
        let fileURL = directory.appendingPathComponent(uniqueFileName)

        do {
            try data.write(to: fileURL)
            logger.info("Saved document: \(uniqueFileName) for journey: \(journeyId)")
            return fileURL
        } catch {
            logger.error("Failed to save document: \(error)")
            return nil
        }
    }

    /// Saves a file from a source URL to the journey documents directory
    func saveDocument(from sourceURL: URL, journeyId: UUID) -> (url: URL, fileName: String, fileSize: Int64)? {
        let directory = getJourneyDocumentsDirectory(journeyId: journeyId)
        let originalFileName = sourceURL.lastPathComponent
        let uniqueFileName = generateUniqueFileName(originalFileName, in: directory)
        let destinationURL = directory.appendingPathComponent(uniqueFileName)

        do {
            // Start accessing security-scoped resource if needed
            let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = (attributes[.size] as? Int64) ?? 0

            logger.info("Copied document: \(uniqueFileName) for journey: \(journeyId)")
            return (destinationURL, uniqueFileName, fileSize)
        } catch {
            logger.error("Failed to copy document: \(error)")
            return nil
        }
    }

    /// Loads document data from the file system
    func loadDocument(fileName: String, journeyId: UUID) -> Data? {
        let fileURL = getJourneyDocumentsDirectory(journeyId: journeyId).appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.warning("Document not found: \(fileName)")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            logger.info("Loaded document: \(fileName)")
            return data
        } catch {
            logger.error("Failed to load document: \(error)")
            return nil
        }
    }

    /// Returns the file URL for a document
    func getDocumentURL(fileName: String, journeyId: UUID) -> URL {
        return getJourneyDocumentsDirectory(journeyId: journeyId).appendingPathComponent(fileName)
    }

    /// Checks if a document file exists
    func documentExists(fileName: String, journeyId: UUID) -> Bool {
        let fileURL = getDocumentURL(fileName: fileName, journeyId: journeyId)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Deletes a document from the file system
    func deleteDocument(fileName: String, journeyId: UUID) -> Bool {
        let fileURL = getJourneyDocumentsDirectory(journeyId: journeyId).appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.warning("Document not found for deletion: \(fileName)")
            return true // Consider it deleted if it doesn't exist
        }

        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted document: \(fileName)")
            return true
        } catch {
            logger.error("Failed to delete document: \(error)")
            return false
        }
    }

    /// Deletes all documents for a journey
    func deleteAllDocuments(journeyId: UUID) -> Bool {
        let directory = getJourneyDocumentsDirectory(journeyId: journeyId)

        do {
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
                logger.info("Deleted all documents for journey: \(journeyId)")
            }
            return true
        } catch {
            logger.error("Failed to delete documents for journey: \(error)")
            return false
        }
    }

    // MARK: - File Info

    /// Returns the file size for a document
    func getFileSize(fileName: String, journeyId: UUID) -> Int64 {
        let fileURL = getDocumentURL(fileName: fileName, journeyId: journeyId)

        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return (attributes[.size] as? Int64) ?? 0
        } catch {
            logger.error("Failed to get file size: \(error)")
            return 0
        }
    }

    /// Determines the document type from a file URL
    func getDocumentType(from url: URL) -> DocumentType {
        let ext = url.pathExtension.lowercased()
        return DocumentType.fromExtension(ext)
    }

    /// Returns the total size of all documents for a journey
    func getTotalSize(journeyId: UUID) -> Int64 {
        let directory = getJourneyDocumentsDirectory(journeyId: journeyId)

        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for fileURL in contents {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }

    // MARK: - Helper Methods

    /// Generates a unique file name to avoid conflicts
    private func generateUniqueFileName(_ originalName: String, in directory: URL) -> String {
        let fileURL = directory.appendingPathComponent(originalName)

        if !fileManager.fileExists(atPath: fileURL.path) {
            return originalName
        }

        // Extract name and extension
        let nameWithoutExtension = (originalName as NSString).deletingPathExtension
        let fileExtension = (originalName as NSString).pathExtension

        var counter = 1
        var newName: String

        repeat {
            if fileExtension.isEmpty {
                newName = "\(nameWithoutExtension)_\(counter)"
            } else {
                newName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
            }
            counter += 1
        } while fileManager.fileExists(atPath: directory.appendingPathComponent(newName).path)

        return newName
    }

    /// Validates that a file is a supported document type
    func isSupportedFileType(_ url: URL) -> Bool {
        let supportedExtensions = ["pdf", "jpg", "jpeg", "png", "heic"]
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }

    /// Returns the formatted file size string
    func formattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
