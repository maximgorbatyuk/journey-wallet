# JWF-2: Document Storage Browser (Developer Feature)

## Overview

Add a debugging feature to browse the app's document storage directory. This allows developers to inspect all files stored in the app's shared container, regardless of whether they are tracked by the Document entity in the database.

**Location:** Developer Section in User Settings

## Requirements

1. Show all files in the document storage directory (`AppGroupContainer.documentsURL`)
2. Display file metadata (name, size, type, modification date)
3. Navigate into journey subdirectories
4. Allow viewing, sharing, and deleting files
5. Show storage usage statistics
6. Independent of Document entity (raw file system access)

## Technical Analysis

### Document Storage Structure

```
AppGroupContainer.containerURL/
└── JourneyDocuments/           <- AppGroupContainer.documentsURL
    ├── <journey-uuid-1>/
    │   ├── passport.pdf
    │   ├── ticket.jpg
    │   └── hotel_booking.pdf
    ├── <journey-uuid-2>/
    │   └── visa.png
    └── ...
```

### Existing Patterns

- `DocumentService.swift` - handles document operations
- `AppGroupContainer.swift` - provides storage URLs
- `UserSettingsTableContentView` - example of developer debug view pattern
- Developer section uses simple buttons with icons

---

## UI Mockups

### 1. Developer Section Button

```
┌─────────────────────────────────────────────────────────┐
│  Developer section                                       │
├─────────────────────────────────────────────────────────┤
│  🔔  Request Permission                                  │
│  🔔  Send Notification Now                               │
│  🔔  Schedule for 5 seconds                              │
│  🗑️  Delete all data                                     │
│  🎲  Generate Random Data                            >   │
│  📋  View user_settings table                        >   │
│  🔄  Reset Migration                                     │
│  📁  Browse Document Storage                         >   │  <- NEW
└─────────────────────────────────────────────────────────┘
```

### 2. Document Storage Browser View

```
┌─────────────────────────────────────────────────────────┐
│  < Back          Document Storage              Done     │
├─────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────┐  │
│  │  Storage Usage                                    │  │
│  │  ████████░░░░░░░░░░░░░░░  15.2 MB used           │  │
│  │  12 files in 3 folders                           │  │
│  └───────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│  📁 Folders                                              │
├─────────────────────────────────────────────────────────┤
│  📁  550e8400-e29b-41d4-a716-446655440000          >    │
│      3 files • 4.2 MB                                   │
│  ─────────────────────────────────────────────────────  │
│  📁  6ba7b810-9dad-11d1-80b4-00c04fd430c8          >    │
│      5 files • 8.1 MB                                   │
│  ─────────────────────────────────────────────────────  │
│  📁  6ba7b811-9dad-11d1-80b4-00c04fd430c8          >    │
│      4 files • 2.9 MB                                   │
├─────────────────────────────────────────────────────────┤
│  📄 Root Files (if any)                                  │
├─────────────────────────────────────────────────────────┤
│  (No files in root directory)                           │
└─────────────────────────────────────────────────────────┘
```

### 3. Folder Contents View

```
┌─────────────────────────────────────────────────────────┐
│  < Back       550e8400-e29b...                  Done    │
├─────────────────────────────────────────────────────────┤
│  Journey: Summer Trip to Italy                          │
│  (or "Unknown Journey" if not found in DB)              │
├─────────────────────────────────────────────────────────┤
│  📄  passport_scan.pdf                              >   │
│      PDF • 1.2 MB • Dec 15, 2025                        │
│  ─────────────────────────────────────────────────────  │
│  🖼️  hotel_booking.jpg                              >   │
│      Image • 856 KB • Dec 16, 2025                      │
│  ─────────────────────────────────────────────────────  │
│  📄  flight_ticket.pdf                              >   │
│      PDF • 2.1 MB • Dec 14, 2025                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Swipe left on file to delete                          │
└─────────────────────────────────────────────────────────┘
```

### 4. File Detail / Actions

```
┌─────────────────────────────────────────────────────────┐
│                    passport_scan.pdf                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    ┌─────────┐                          │
│                    │   PDF   │                          │
│                    │  icon   │                          │
│                    └─────────┘                          │
│                                                         │
│  File Name:     passport_scan.pdf                       │
│  Type:          PDF Document                            │
│  Size:          1.2 MB                                  │
│  Created:       Dec 15, 2025, 10:30 AM                  │
│  Modified:      Dec 15, 2025, 10:30 AM                  │
│  Path:          .../550e8400.../passport_scan.pdf       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐    │
│  │  👁️  Quick Look                                 │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  📤  Share File                                 │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  🗑️  Delete File                                │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Data Layer

#### 1.1 Create DocumentStorageService

Create `JourneyWallet/Services/DocumentStorageService.swift`:

```swift
import Foundation
import os

/// Service for browsing raw document storage (developer debugging)
class DocumentStorageService {

    static let shared = DocumentStorageService()

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-",
                                 category: "DocumentStorageService")

    /// Returns the root documents directory
    var rootDirectory: URL {
        AppGroupContainer.documentsURL
    }

    /// Get all items (files and folders) in a directory
    func getContents(of directory: URL) -> [StorageItem]

    /// Get storage statistics
    func getStorageStats() -> StorageStats

    /// Delete a file
    func deleteFile(at url: URL) -> Bool

    /// Get file attributes
    func getFileAttributes(at url: URL) -> FileAttributes?
}
```

#### 1.2 Create Storage Models

Add to `DocumentStorageService.swift` or separate file:

```swift
struct StorageItem: Identifiable {
    let id: UUID = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let fileCount: Int?  // For directories

    var icon: String {
        if isDirectory { return "folder.fill" }
        // Return appropriate icon based on extension
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct StorageStats {
    let totalSize: Int64
    let fileCount: Int
    let folderCount: Int

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

struct FileAttributes {
    let name: String
    let path: String
    let size: Int64
    let type: String
    let creationDate: Date?
    let modificationDate: Date?
}
```

### Phase 2: View Layer

#### 2.1 Create DocumentStorageBrowserView

Create `JourneyWallet/Developer/DocumentStorageBrowserView.swift`:

```swift
struct DocumentStorageBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storageStats: StorageStats?
    @State private var folders: [StorageItem] = []
    @State private var rootFiles: [StorageItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            List {
                // Storage stats section
                if let stats = storageStats {
                    StorageStatsSection(stats: stats)
                }

                // Folders section
                if !folders.isEmpty {
                    Section(header: Text("Folders")) {
                        ForEach(folders) { folder in
                            NavigationLink(destination: FolderContentsView(folder: folder)) {
                                FolderRow(item: folder)
                            }
                        }
                    }
                }

                // Root files section
                if !rootFiles.isEmpty {
                    Section(header: Text("Root Files")) {
                        ForEach(rootFiles) { file in
                            FileRow(item: file)
                        }
                    }
                }
            }
            .navigationTitle("Document Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadData() }
        }
    }
}
```

#### 2.2 Create FolderContentsView

Create `JourneyWallet/Developer/FolderContentsView.swift`:

```swift
struct FolderContentsView: View {
    let folder: StorageItem

    @State private var files: [StorageItem] = []
    @State private var journeyName: String?
    @State private var selectedFile: StorageItem?
    @State private var showDeleteConfirmation = false
    @State private var fileToDelete: StorageItem?

    var body: some View {
        List {
            // Journey info header (if UUID matches a journey)
            if let name = journeyName {
                Section {
                    HStack {
                        Image(systemName: "suitcase.fill")
                            .foregroundColor(.blue)
                        Text("Journey: \(name)")
                            .font(.subheadline)
                    }
                }
            }

            // Files list
            Section {
                ForEach(files) { file in
                    FileRow(item: file)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                fileToDelete = file
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            selectedFile = file
                        }
                }
            }
        }
        .navigationTitle(folder.name.prefix(12) + "...")
        .sheet(item: $selectedFile) { file in
            FileDetailView(file: file)
        }
        .alert("Delete File?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let file = fileToDelete {
                    deleteFile(file)
                }
            }
        }
        .onAppear { loadData() }
    }
}
```

#### 2.3 Create FileDetailView

Create `JourneyWallet/Developer/FileDetailView.swift`:

```swift
struct FileDetailView: View {
    let file: StorageItem

    @Environment(\.dismiss) private var dismiss
    @State private var attributes: FileAttributes?
    @State private var showQuickLook = false
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            List {
                // File icon and name
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: file.icon)
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                            Text(file.name)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }

                // File info
                Section(header: Text("File Information")) {
                    InfoRow(label: "Type", value: attributes?.type ?? "Unknown")
                    InfoRow(label: "Size", value: file.formattedSize)
                    if let created = attributes?.creationDate {
                        InfoRow(label: "Created", value: formatDate(created))
                    }
                    if let modified = attributes?.modificationDate {
                        InfoRow(label: "Modified", value: formatDate(modified))
                    }
                    InfoRow(label: "Path", value: attributes?.path ?? file.url.path)
                }

                // Actions
                Section {
                    Button {
                        showQuickLook = true
                    } label: {
                        Label("Quick Look", systemImage: "eye")
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share File", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete File", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("File Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .quickLookPreview($showQuickLook, url: file.url)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [file.url])
            }
            .alert("Delete File?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteFile()
                    dismiss()
                }
            }
        }
    }
}
```

#### 2.4 Create Supporting Views

```swift
// StorageStatsSection
struct StorageStatsSection: View {
    let stats: StorageStats

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Storage Usage")
                    .font(.headline)

                Text(stats.formattedTotalSize)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("\(stats.fileCount) files in \(stats.folderCount) folders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

// FolderRow
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
                    Text("\(count) files \u{2022} \(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// FileRow
struct FileRow: View {
    let item: StorageItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(fileType) \u{2022} \(item.formattedSize) \u{2022} \(formatDate(item.modificationDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

### Phase 3: Integration

#### 3.1 Add Button to Developer Section

In `UserSettingsView.swift`, add to Developer section:

```swift
Button(action: {
    showDocumentStorageBrowser = true
}) {
    HStack {
        Image(systemName: "folder.fill")
            .foregroundColor(.cyan)
        Text("Browse Document Storage")
            .foregroundColor(.primary)
    }
}
.buttonStyle(.plain)
```

Add state variable:
```swift
@State private var showDocumentStorageBrowser = false
```

Add sheet modifier:
```swift
.sheet(isPresented: $showDocumentStorageBrowser) {
    DocumentStorageBrowserView()
}
```

### Phase 4: Localization

Add keys to all 6 language files:

```
/* Developer - Document Storage Browser */
"developer.document_storage.title" = "Document Storage";
"developer.document_storage.button" = "Browse Document Storage";
"developer.document_storage.stats.title" = "Storage Usage";
"developer.document_storage.stats.files_folders" = "%d files in %d folders";
"developer.document_storage.folders" = "Folders";
"developer.document_storage.root_files" = "Root Files";
"developer.document_storage.no_files" = "No files in this directory";
"developer.document_storage.unknown_journey" = "Unknown Journey";
"developer.document_storage.file_info" = "File Information";
"developer.document_storage.type" = "Type";
"developer.document_storage.size" = "Size";
"developer.document_storage.created" = "Created";
"developer.document_storage.modified" = "Modified";
"developer.document_storage.path" = "Path";
"developer.document_storage.quick_look" = "Quick Look";
"developer.document_storage.share" = "Share File";
"developer.document_storage.delete" = "Delete File";
"developer.document_storage.delete_confirm.title" = "Delete File?";
"developer.document_storage.delete_confirm.message" = "This file will be permanently deleted from storage.";
```

---

## File Structure

```
JourneyWallet/
└── Developer/
    ├── DocumentStorageBrowserView.swift    <- Main browser view
    ├── FolderContentsView.swift            <- Folder contents list
    ├── FileDetailView.swift                <- File details and actions
    └── DocumentStorageService.swift        <- File system operations
```

---

## Acceptance Criteria

1. [ ] Button "Browse Document Storage" visible in Developer Section (only when developer mode is enabled)
2. [ ] Shows storage statistics (total size, file count, folder count)
3. [ ] Lists all journey folders with file counts and sizes
4. [ ] Can navigate into folders to see files
5. [ ] Shows journey name if folder UUID matches a journey in database
6. [ ] Can view file details (name, size, type, dates, path)
7. [ ] Can preview files with Quick Look
8. [ ] Can share files via share sheet
9. [ ] Can delete files with confirmation
10. [ ] Files list updates after deletion
11. [ ] Proper localization for all supported languages

---

## Dependencies

- `QuickLook` framework for file preview
- Existing `ShareSheet` component
- `AppGroupContainer` for storage URLs
- `DatabaseManager` for journey name lookup

---

## Notes

- This feature is for debugging only - not visible to regular users
- Shows raw file system contents, not database Document records
- Helps identify orphaned files or storage issues
- UUID-based folder names can be matched to Journey records for context
