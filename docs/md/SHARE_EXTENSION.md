# Share Extension Documentation

## Overview

The Share Extension allows users to share files (PDFs, images) from other apps directly into Journey Wallet. Users can select which journey to add the document to and optionally provide a custom display name.

### User Flow

1. User opens a file in another app (Mail, Files, Safari, etc.)
2. User taps the Share button
3. User selects "Journey Wallet" from the Share sheet
4. Share Extension UI appears with:
   - Original filename (read-only)
   - Optional "Document name" field
   - Journey picker (sorted: active → upcoming → past)
5. User selects a journey and optionally enters a custom name
6. File is saved to the selected journey's documents

---

## Architecture

### Single Target with Dynamic Configuration

Instead of separate targets for Dev and Production, we use a **single ShareExtension target** with xcconfig-based configuration. This approach:

- Simplifies maintenance (one target instead of two)
- Works correctly with Xcode Cloud
- Uses standard embedding mechanisms
- Keeps Dev and Production data isolated via different App Groups

### Configuration by Build Type

| Setting | Debug (Dev) | Release (Production) |
|---------|-------------|----------------------|
| App Bundle ID | `dev.mgorbatyuk.JourneyWallet.dev` | `dev.mgorbatyuk.JourneyWallet` |
| Extension Bundle ID | `dev.mgorbatyuk.JourneyWallet.dev.ShareExtension` | `dev.mgorbatyuk.JourneyWallet.ShareExtension` |
| App Group | `group.dev.mgorbatyuk.journeywallet.dev` | `group.dev.mgorbatyuk.journeywallet` |

---

## File Structure

```
ShareExtension/
├── Info.plist                      # Extension configuration
├── ShareExtension.entitlements     # Release entitlements (production App Group)
├── ShareExtensionDebug.entitlements # Debug entitlements (dev App Group)
├── ShareViewController.swift       # Entry point, extracts files from Share sheet
├── ShareView.swift                 # SwiftUI interface
├── ShareViewModel.swift            # Business logic, saves documents
└── Base.lproj/
```

---

## Configuration Files

### xcconfig Settings

**JourneyWallet/Config/Base.xcconfig:**
```
APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.journeywallet
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.JourneyWallet.ShareExtension
```

**JourneyWallet/Config/Debug.xcconfig:**
```
#include "Base.xcconfig"
APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.journeywallet.dev
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.JourneyWallet.dev.ShareExtension
```

**JourneyWallet/Config/Release.xcconfig:**
```
#include "Base.xcconfig"
APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.journeywallet
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.JourneyWallet.ShareExtension
```

### ShareExtension/Info.plist

```xml
<key>AppGroupIdentifier</key>
<string>$(APP_GROUP_IDENTIFIER)</string>
<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>
<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>
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
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

### Entitlements

**ShareExtension.entitlements (Release):**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.dev.mgorbatyuk.journeywallet</string>
</array>
```

**ShareExtensionDebug.entitlements (Debug):**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.dev.mgorbatyuk.journeywallet.dev</string>
</array>
```

---

## Xcode Project Configuration

### Build Settings (ShareExtension target)

| Setting | Value |
|---------|-------|
| Product Bundle Identifier | `$(SHARE_EXTENSION_BUNDLE_ID)` |
| Code Signing Entitlements (Debug) | `ShareExtension/ShareExtensionDebug.entitlements` |
| Code Signing Entitlements (Release) | `ShareExtension/ShareExtension.entitlements` |
| Configuration Files | Same as main app (Debug.xcconfig, Release.xcconfig) |

### Target Membership

The ShareExtension target includes:

**Required BusinessLogic files:**
- Models (Journey, Document, Currency, etc.)
- Database (DatabaseManager, repositories)
- DocumentService
- AppGroupContainer
- LocalizationManager

**Excluded from extension** (not compatible with extension context):
- AnalyticsService (requires Firebase)
- BackgroundTaskManager (uses BGTaskScheduler)
- BackupService
- NetworkMonitor
- NotificationManager
- ReminderService
- Other services not needed for sharing

**Localization files:**
- All `.lproj` folders must be added to ShareExtension target membership for `L()` function to work

---

## Data Flow

### Shared App Group Container

Both the main app and Share Extension access the same data through the App Group container:

```
App Group Container/
├── journey_wallet.sqlite3    # Shared database
├── journey_wallet.sqlite3-wal
├── journey_wallet.sqlite3-shm
└── JourneyDocuments/         # Shared documents folder
    └── {journeyId}/
        └── {filename}
```

### Database Migration

On first launch after update, `DatabaseMigrationHelper` migrates existing data from the app's private container to the shared App Group container:

1. Copies database files
2. Copies documents folder
3. Sets migration flag in UserDefaults
4. Cleans up old files

Migration runs in `DatabaseManager.init()` before opening the database connection.

---

## UI Components

### ShareViewController

Entry point for the extension. Responsibilities:
- Extracts files from `NSExtensionContext`
- Copies files to temporary directory
- Presents SwiftUI interface via `UIHostingController`
- Handles completion/cancellation

### ShareView

SwiftUI interface displaying:
- **File section**: Original filename with icon, optional "Document name" field
- **Journey section**: Picker with journeys sorted by relevance (active → upcoming → past)
- **Error section**: Shows errors if database access fails
- **Saving overlay**: Progress indicator during save

### ShareViewModel

Business logic:
- Loads journeys from shared database
- Pre-selects active or upcoming journey
- Saves documents to shared container
- Creates Document records in database

---

## Localization

### Keys

```
/* Share Extension */
"share.title" = "Save to Journey Wallet";
"share.file_section" = "File";
"share.journey_section" = "Add to Journey";
"share.document_name" = "Document name";
"share.document_name_placeholder" = "Enter document name";
"share.no_journeys" = "No journeys found";
"share.no_journeys_hint" = "Create a journey in the app first";
"share.saving" = "Saving...";
"share.error.database" = "Could not access database";
"share.error.save_failed" = "Failed to save document";
"share.error.no_journey" = "Please select a journey";
```

### Supported Languages

- English (en)
- Russian (ru)
- German (de)
- Ukrainian (uk)
- Turkish (tr)
- Kazakh (kk)

---

## Supported File Types

The extension accepts:
- **Files**: Up to 10 files per share (PDF, documents, etc.)
- **Images**: Up to 10 images per share (JPEG, PNG, HEIC)

Configured via `NSExtensionActivationRule` in Info.plist.

---

## Limitations & Considerations

### Memory Limit

Share Extensions have ~120MB memory limit. For large files:
- Files are streamed/copied, not loaded into memory
- Processed one at a time
- Temporary files cleaned up after save

### No Background Processing

Extensions cannot run background tasks. All work must complete before the extension closes.

### Database Access

The extension opens a read/write connection to the shared database. SQLite handles concurrent access from main app and extension.

---

## Testing Checklist

### Development (Debug build)

- [ ] Extension appears in Share sheet as "JourneyWallet-Dev"
- [ ] Can share PDF from Files app
- [ ] Can share image from Photos app
- [ ] Can share attachment from Mail app
- [ ] Journey picker shows all journeys (sorted correctly)
- [ ] Active journey is pre-selected
- [ ] Optional document name field works
- [ ] Empty name → uses filename as display name
- [ ] Custom name → uses custom name as display name
- [ ] Document appears in journey after save
- [ ] Cancel button works

### Production (Release build)

- [ ] Extension appears as "Journey Wallet"
- [ ] Uses production App Group
- [ ] Data isolated from Dev app

### Edge Cases

- [ ] No journeys exist → shows "No journeys found" message
- [ ] Multiple files at once
- [ ] Large files (>10MB)
- [ ] Very long filenames
- [ ] Special characters in filenames

---

## Troubleshooting

### Extension doesn't appear in Share sheet

1. Ensure extension is embedded in main app (General → Frameworks, Libraries, and Embedded Content)
2. Check bundle ID prefix matches parent app
3. Rebuild and reinstall app

### "Could not access database" error

1. Verify App Group is configured in both app and extension entitlements
2. Check `AppGroupIdentifier` in extension's Info.plist matches xcconfig
3. Ensure extension uses correct entitlements file for build configuration

### Localization keys shown instead of text

1. Add all `.lproj` folders to ShareExtension target membership
2. Ensure `LocalizationManager.swift` is in extension target

### Documents not appearing in main app

1. Verify both app and extension use same App Group
2. Check database path points to shared container
3. Ensure DocumentService uses `AppGroupContainer.documentsURL`
