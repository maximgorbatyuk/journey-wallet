# Share Extension Implementation Plan

## Overview

Implement iOS Share Extension to allow users to share PDF files (flight tickets, hotel bookings, etc.) from other apps directly into Journey Wallet.

### User Flow
1. User receives email with PDF attachment (e.g., flight ticket)
2. User opens PDF and taps Share button
3. User selects "Journey Wallet" from Share sheet
4. App shows dialog with:
   - Journey picker (dropdown of existing journeys)
   - Document name field (pre-filled from filename)
   - Save/Cancel buttons
5. File is saved to selected journey's documents

---

## Build Configurations

The app has two build configurations:
- **Debug (Dev)** - Development build with bundle ID `dev.mgorbatyuk.JourneyWallet.dev`
- **Release (Prod)** - Production build with bundle ID `dev.mgorbatyuk.JourneyWallet`

Each configuration needs its own App Group to keep data separate and allow testing the Share Extension with the dev app.

### Summary: Dev vs Prod Setup

| Component | Development | Production |
|-----------|-------------|------------|
| Main App Bundle ID | `dev.mgorbatyuk.JourneyWallet.dev` | `dev.mgorbatyuk.JourneyWallet` |
| Extension Bundle ID | `dev.mgorbatyuk.JourneyWallet.dev.ShareExtension` | `dev.mgorbatyuk.JourneyWallet.ShareExtension` |
| App Group | `group.dev.mgorbatyuk.journeywallet.dev` | `group.dev.mgorbatyuk.journeywallet` |
| Extension Target | `ShareExtensionDev` | `ShareExtension` |
| Share Sheet Name | "JourneyWallet-Dev" | "Journey Wallet" |

This setup ensures:
1. Dev and Prod apps have completely separate data
2. You can test Share Extension with Dev app without affecting production
3. Both apps can be installed on the same device simultaneously

---

## Phase 1: App Group Setup

### 1.1 Create App Groups in Apple Developer Portal
- [ ] Log into Apple Developer Portal
- [ ] Go to Certificates, Identifiers & Profiles → Identifiers
- [ ] Create **two** App Group identifiers:
  - **Production**: `group.dev.mgorbatyuk.journeywallet`
  - **Development**: `group.dev.mgorbatyuk.journeywallet.dev`

### 1.2 Enable App Groups Capability for Main App
- [ ] Open Xcode project settings
- [ ] Select main app target → Signing & Capabilities
- [ ] Add "App Groups" capability
- [ ] Select **both** App Groups (Xcode will use the correct one based on build config)

### 1.3 Configure App Group Selection by Build Configuration

**Option A: Using Build Settings (Recommended)**

Add a user-defined build setting in Xcode:

1. Select project → Build Settings → Add User-Defined Setting
2. Name: `APP_GROUP_IDENTIFIER`
3. Values:
   - Debug: `group.dev.mgorbatyuk.journeywallet.dev`
   - Release: `group.dev.mgorbatyuk.journeywallet`

Then reference in code via Info.plist:

**File: `Info.plist`** (add new key)
```xml
<key>AppGroupIdentifier</key>
<string>$(APP_GROUP_IDENTIFIER)</string>
```

**Option B: Using Compiler Flags**

The code can use `#if DEBUG` to select the appropriate App Group:

```swift
enum AppGroupContainer {
    static var identifier: String {
        #if DEBUG
        return "group.dev.mgorbatyuk.journeywallet.dev"
        #else
        return "group.dev.mgorbatyuk.journeywallet"
        #endif
    }
}
```

**Note:** Option B is simpler but Option A is more flexible if you have additional build configurations.

### 1.3 Migrate Database to Shared Container

**File: `BusinessLogic/Database/DatabaseManager.swift`**

Current database path uses app's default container. Need to change to shared container:

```swift
// Before
let dbPath = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)
    .first!
    .appendingPathComponent("journey_wallet.sqlite3")

// After
static let appGroupIdentifier = "group.dev.mgorbatyuk.journeywallet"

var dbPath: URL {
    guard let containerURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) else {
        fatalError("App Group container not found")
    }
    return containerURL.appendingPathComponent("journey_wallet.sqlite3")
}
```

**Migration Strategy:**
1. Check if old database exists in app container
2. If yes, copy to shared container
3. Delete old database after successful copy
4. Always use shared container path going forward

### 1.4 Migrate Document Storage to Shared Container

**File: `BusinessLogic/Services/DocumentService.swift`**

```swift
// Before
let documentsPath = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)
    .first!
    .appendingPathComponent("JourneyDocuments")

// After
var documentsPath: URL {
    guard let containerURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: DatabaseManager.appGroupIdentifier) else {
        fatalError("App Group container not found")
    }
    return containerURL.appendingPathComponent("JourneyDocuments")
}
```

---

## Phase 2: Create Share Extension Targets

We need **two** Share Extension targets to match the main app configurations:
- `ShareExtension` - for Production app
- `ShareExtensionDev` - for Development app

Each extension must be embedded in its respective app and use the matching App Group.

### 2.1 Add Share Extension Target (Production)
- [ ] In Xcode: File → New → Target
- [ ] Select "Share Extension"
- [ ] Name: `ShareExtension`
- [ ] Language: Swift
- [ ] Bundle Identifier: `dev.mgorbatyuk.JourneyWallet.ShareExtension`
- [ ] Embed in: JourneyWallet (Production scheme)
- [ ] Enable App Groups capability
- [ ] Select: `group.dev.mgorbatyuk.journeywallet`

### 2.2 Add Share Extension Target (Development)
- [ ] In Xcode: File → New → Target
- [ ] Select "Share Extension"
- [ ] Name: `ShareExtensionDev`
- [ ] Language: Swift
- [ ] Bundle Identifier: `dev.mgorbatyuk.JourneyWallet.dev.ShareExtension`
- [ ] Embed in: JourneyWallet (Debug scheme)
- [ ] Enable App Groups capability
- [ ] Select: `group.dev.mgorbatyuk.journeywallet.dev`

### 2.3 Share Code Between Extensions

To avoid duplicating code, create a shared framework or use file references:

**Option A: Shared Files (Simpler)**
1. Create shared Swift files in a common folder (e.g., `ShareExtensionShared/`)
2. Add files to both extension targets' "Compile Sources"
3. Use `#if DEBUG` for App Group identifier

**Option B: Shared Framework (Cleaner but more setup)**
1. Create a new Framework target: `ShareExtensionKit`
2. Move shared code (ShareView, ShareViewModel) to framework
3. Link framework to both extension targets

**Recommended: Option A** for simplicity. The code difference is minimal (just App Group ID).

### 2.4 Configure Build Schemes

Update schemes to embed the correct extension:

**Debug Scheme:**
- Build: JourneyWallet, ShareExtensionDev
- Embed: ShareExtensionDev.appex

**Release Scheme:**
- Build: JourneyWallet, ShareExtension
- Embed: ShareExtension.appex

### 2.5 Configure Info.plist

**File: `ShareExtension/Info.plist`** (same for both extensions)

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>10</integer>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

Alternatively, use predicate for more specific file types:
```xml
<key>NSExtensionActivationRule</key>
<string>SUBQUERY (
    extensionItems,
    $extensionItem,
    SUBQUERY (
        $extensionItem.attachments,
        $attachment,
        ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.data"
    ).@count >= 1
).@count >= 1</string>
```

### 2.6 Project Structure

```
ShareExtensionShared/              # Shared code (added to both targets)
├── ShareViewController.swift      # Entry point
├── ShareView.swift                # SwiftUI UI
└── ShareViewModel.swift           # Business logic

ShareExtension/                    # Production extension
├── ShareExtension.entitlements    # Contains: group.dev.mgorbatyuk.journeywallet
├── Info.plist
└── Assets.xcassets

ShareExtensionDev/                 # Development extension
├── ShareExtensionDev.entitlements # Contains: group.dev.mgorbatyuk.journeywallet.dev
├── Info.plist
└── Assets.xcassets
```

**Note:** The shared Swift files are referenced by both targets. Only entitlements differ.

---

## Phase 3: Share Extension UI

### 3.1 ShareViewController.swift

```swift
import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Extract shared items
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        // Find attachments
        var fileURLs: [URL] = []
        let group = DispatchGroup()

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                group.enter()

                // Try PDF first, then general file
                let typeIdentifier = UTType.pdf.identifier

                if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                    provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                        if let url = url {
                            // Copy to temp location (provider's URL is temporary)
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(url.lastPathComponent)
                            try? FileManager.default.copyItem(at: url, to: tempURL)
                            fileURLs.append(tempURL)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.presentShareUI(with: fileURLs)
        }
    }

    private func presentShareUI(with fileURLs: [URL]) {
        let viewModel = ShareViewModel(
            fileURLs: fileURLs,
            onSave: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: NSError(
                    domain: "ShareExtension",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
                ))
            }
        )

        let shareView = ShareView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: shareView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }

    private func close() {
        extensionContext?.cancelRequest(withError: NSError(
            domain: "ShareExtension",
            code: 0,
            userInfo: nil
        ))
    }
}
```

### 3.2 ShareView.swift

```swift
import SwiftUI

struct ShareView: View {
    @ObservedObject var viewModel: ShareViewModel

    var body: some View {
        NavigationView {
            Form {
                // File info section
                Section(header: Text("File")) {
                    ForEach(viewModel.files, id: \.url) { file in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading) {
                                TextField("Document name", text: file.$name)
                                    .font(.headline)

                                Text(file.originalName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Journey picker section
                Section(header: Text("Add to Journey")) {
                    if viewModel.journeys.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "suitcase")
                                .font(.largeTitle)
                                .foregroundColor(.gray)

                            Text("No journeys found")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Text("Create a journey in the app first")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Picker("Journey", selection: $viewModel.selectedJourneyId) {
                            ForEach(viewModel.journeys) { journey in
                                HStack {
                                    Text(journey.name)
                                    if !journey.destination.isEmpty {
                                        Text("(\(journey.destination))")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(journey.id as UUID?)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Save to Journey Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
}
```

### 3.3 ShareViewModel.swift

```swift
import Foundation
import Combine

class FileItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let originalName: String
    @Published var name: String

    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        self.name = url.deletingPathExtension().lastPathComponent
    }
}

@MainActor
class ShareViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var journeys: [Journey] = []
    @Published var selectedJourneyId: UUID?
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let onSave: () -> Void
    private let onCancel: () -> Void

    // Access shared database
    private let journeysRepository: JourneysRepository?
    private let documentsRepository: DocumentsRepository?
    private let documentService: DocumentService

    var canSave: Bool {
        selectedJourneyId != nil && !files.isEmpty && !isSaving
    }

    init(fileURLs: [URL], onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize with shared database
        // Note: DatabaseManager must use App Group container
        self.journeysRepository = DatabaseManager.shared.journeysRepository
        self.documentsRepository = DatabaseManager.shared.documentsRepository
        self.documentService = DocumentService.shared

        // Create file items
        self.files = fileURLs.map { FileItem(url: $0) }

        // Load journeys
        loadJourneys()
    }

    private func loadJourneys() {
        // Fetch all journeys, prioritize active/upcoming
        guard let repository = journeysRepository else {
            errorMessage = "Could not access database"
            return
        }

        let allJourneys = repository.fetchAll()

        // Sort: active first, then upcoming, then past
        journeys = allJourneys.sorted { j1, j2 in
            if j1.isActive && !j2.isActive { return true }
            if !j1.isActive && j2.isActive { return false }
            if j1.isUpcoming && !j2.isUpcoming { return true }
            if !j1.isUpcoming && j2.isUpcoming { return false }
            return j1.startDate > j2.startDate
        }

        // Pre-select first active or upcoming journey
        selectedJourneyId = journeys.first(where: { $0.isActive })?.id
            ?? journeys.first(where: { $0.isUpcoming })?.id
            ?? journeys.first?.id
    }

    func save() {
        guard let journeyId = selectedJourneyId else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                for file in files {
                    // Copy file to app's document storage
                    let savedURL = try documentService.saveDocument(
                        from: file.url,
                        forJourney: journeyId,
                        withName: file.name
                    )

                    // Create database record
                    let document = Document(
                        id: UUID(),
                        journeyId: journeyId,
                        name: file.name,
                        fileName: savedURL.lastPathComponent,
                        fileType: file.url.pathExtension.lowercased(),
                        fileSize: try? FileManager.default.attributesOfItem(atPath: savedURL.path)[.size] as? Int64,
                        createdAt: Date(),
                        notes: nil
                    )

                    documentsRepository?.insert(document)

                    // Clean up temp file
                    try? FileManager.default.removeItem(at: file.url)
                }

                isSaving = false
                onSave()

            } catch {
                isSaving = false
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }

    func cancel() {
        // Clean up temp files
        for file in files {
            try? FileManager.default.removeItem(at: file.url)
        }
        onCancel()
    }
}
```

---

## Phase 4: Data Handling Details

### 4.1 Shared Container Helper

**File: `BusinessLogic/Helpers/AppGroupContainer.swift`**

This helper automatically selects the correct App Group based on build configuration.

```swift
import Foundation
import os

enum AppGroupContainer {
    private static let logger = Logger(subsystem: "AppGroupContainer", category: "Storage")

    /// App Group identifier - differs between Debug and Release builds
    static var identifier: String {
        #if DEBUG
        return "group.dev.mgorbatyuk.journeywallet.dev"
        #else
        return "group.dev.mgorbatyuk.journeywallet"
        #endif
    }

    /// Shared container URL for the App Group
    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            logger.error("App Group '\(identifier)' not configured. Check entitlements.")
            fatalError("App Group '\(identifier)' not configured")
        }
        return url
    }

    /// Database file URL in shared container
    static var databaseURL: URL {
        containerURL.appendingPathComponent("journey_wallet.sqlite3")
    }

    /// Documents directory in shared container
    static var documentsURL: URL {
        let url = containerURL.appendingPathComponent("JourneyDocuments")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Check if App Group is properly configured
    static var isConfigured: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }
}
```

**Important:** Both the main app and Share Extension must use this same helper, so it needs to be:
- In the `BusinessLogic` framework/module, OR
- Added to both main app and extension targets' compile sources

### 4.2 Database Migration

**File: `BusinessLogic/Database/DatabaseMigrationHelper.swift`**

```swift
import Foundation
import os

class DatabaseMigrationHelper {
    private static let logger = Logger(subsystem: "DatabaseMigration", category: "Migration")

    /// Migrates database from old app container to shared App Group container
    static func migrateToAppGroupIfNeeded() {
        let fileManager = FileManager.default

        // Old location (app's Documents directory)
        guard let oldContainerURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let oldDatabasePath = oldContainerURL.appendingPathComponent("journey_wallet.sqlite3")

        // New location (App Group container)
        let newDatabasePath = AppGroupContainer.databaseURL

        // Check if migration is needed
        guard fileManager.fileExists(atPath: oldDatabasePath.path) else {
            logger.info("No old database found, skipping migration")
            return
        }

        guard !fileManager.fileExists(atPath: newDatabasePath.path) else {
            logger.info("New database already exists, skipping migration")
            return
        }

        // Perform migration
        do {
            try fileManager.copyItem(at: oldDatabasePath, to: newDatabasePath)
            logger.info("Database migrated successfully")

            // Also migrate SQLite journal files if they exist
            let walPath = oldDatabasePath.appendingPathExtension("wal")
            let shmPath = oldDatabasePath.appendingPathExtension("shm")

            if fileManager.fileExists(atPath: walPath.path) {
                try fileManager.copyItem(at: walPath, to: newDatabasePath.appendingPathExtension("wal"))
            }
            if fileManager.fileExists(atPath: shmPath.path) {
                try fileManager.copyItem(at: shmPath, to: newDatabasePath.appendingPathExtension("shm"))
            }

            // Migrate documents folder
            let oldDocumentsPath = oldContainerURL.appendingPathComponent("JourneyDocuments")
            if fileManager.fileExists(atPath: oldDocumentsPath.path) {
                try fileManager.copyItem(at: oldDocumentsPath, to: AppGroupContainer.documentsURL)
                logger.info("Documents migrated successfully")
            }

            // Remove old files after successful migration
            try? fileManager.removeItem(at: oldDatabasePath)
            try? fileManager.removeItem(at: walPath)
            try? fileManager.removeItem(at: shmPath)
            try? fileManager.removeItem(at: oldDocumentsPath)

            logger.info("Old files cleaned up")

        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
        }
    }
}
```

### 4.3 Call Migration on App Launch

**File: `JourneyWallet/JourneyWalletApp.swift`**

```swift
// In ForegroundNotificationDelegate.application(_:didFinishLaunchingWithOptions:)
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    // Migrate database to App Group container (one-time migration)
    DatabaseMigrationHelper.migrateToAppGroupIfNeeded()

    // ... rest of existing code
}
```

---

## Phase 5: Testing & Edge Cases

### 5.1 Development Testing (Do This First!)

Test with the **Dev app** before touching production:

- [ ] Install Dev app on simulator/device
- [ ] Verify "JourneyWallet-Dev" appears in Share sheet
- [ ] Create a test journey in Dev app
- [ ] Share a PDF to Dev app
- [ ] Verify file appears in Dev app's journey documents
- [ ] Verify Dev app data is isolated from Production app

**Testing on Simulator:**
1. Build and run Dev scheme
2. Open Files app or Safari
3. Find/download a PDF
4. Tap Share → Select "JourneyWallet-Dev"

**Testing on Device:**
1. Build and run Dev scheme on device
2. Open Mail app with PDF attachment
3. Tap attachment → Share → Select "JourneyWallet-Dev"

### 5.2 Production Testing

After Dev testing passes:

- [ ] Share single PDF from Mail app
- [ ] Share single PDF from Files app
- [ ] Share multiple files at once
- [ ] Share when no journeys exist (show appropriate message)
- [ ] Share large file (test memory limits)
- [ ] Share while offline
- [ ] Cancel share operation
- [ ] Verify file appears in journey's documents after share

### 5.3 Data Isolation Testing

Critical: Verify Dev and Prod data don't mix!

- [ ] Install both Dev and Prod apps on same device
- [ ] Create different journeys in each app
- [ ] Share to Dev app → verify only Dev journeys shown
- [ ] Share to Prod app → verify only Prod journeys shown
- [ ] Verify documents saved to correct app

### 5.4 Edge Cases to Handle
- [ ] No journeys exist → Show message, disable save
- [ ] File name already exists → Append number or timestamp
- [ ] Very long file name → Truncate appropriately
- [ ] Unsupported file type → Show error or accept anyway
- [ ] Database locked → Retry or show error
- [ ] Disk full → Show appropriate error

### 5.5 Memory Considerations
Share Extensions have ~120MB memory limit. For large files:
- Stream file copy instead of loading into memory
- Process one file at a time
- Release resources promptly

---

## Phase 6: Localization

Add keys to all 6 language files:

```
/* Share Extension */
"share.title" = "Save to Journey Wallet";
"share.file_section" = "File";
"share.journey_section" = "Add to Journey";
"share.document_name" = "Document name";
"share.no_journeys" = "No journeys found";
"share.no_journeys_hint" = "Create a journey in the app first";
"share.saving" = "Saving...";
"share.save" = "Save";
"share.cancel" = "Cancel";
"share.error.database" = "Could not access database";
"share.error.save_failed" = "Failed to save document";
```

---

## Implementation Order

1. **Phase 1** - App Group setup and database migration (most critical, foundational)
2. **Phase 2** - Create Share Extension target in Xcode
3. **Phase 3** - Build the UI
4. **Phase 4** - Implement data handling
5. **Phase 5** - Testing
6. **Phase 6** - Localization

---

## Risks & Considerations

| Risk | Mitigation |
|------|------------|
| Database corruption during migration | Backup before migration, copy instead of move |
| Extension memory limits | Stream large files, don't load into memory |
| App Group provisioning issues | Test on real device early with Dev app |
| Breaking existing document access | Thorough testing of main app after migration |
| Dev/Prod data mixing | Use separate App Groups, test isolation thoroughly |
| Entitlements mismatch | Double-check each extension uses correct App Group |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: App Group Setup (x2) | 2-3 hours |
| Phase 2: Extension Targets (x2) | 2 hours |
| Phase 3: Shared UI Code | 2-3 hours |
| Phase 4: Data Handling | 2-3 hours |
| Phase 5: Testing (Dev + Prod) | 3-4 hours |
| Phase 6: Localization | 30 min |
| **Total** | **12-16 hours** |

---

## References

- [Apple: App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)
- [Apple: Share Extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)
- [Apple: App Groups](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)
