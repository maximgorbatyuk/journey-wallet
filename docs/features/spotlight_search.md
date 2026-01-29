# Spotlight Search Integration

## Overview

Make Journey Wallet content searchable via iOS system Spotlight search. When users swipe down on their home screen and type a search query, indexed app content (journeys, hotels, flights, etc.) will appear in results with the option to open directly in the app.

## Current Status

- **No Spotlight integration exists** in the codebase
- No CoreSpotlight imports, NSUserActivity, or indexing logic
- Well-structured data models ready for indexing

## Technology

- **Core Spotlight Framework** (`CoreSpotlight`)
- `CSSearchableItem` for indexing content
- `CSSearchableItemAttributeSet` for item metadata
- `NSUserActivity` for deep linking from search results

---

## Manual Configuration Required

The following steps must be done manually in Xcode before implementing the code changes.

### Checklist

- [ ] Add CoreSpotlight framework to JourneyWallet target
- [ ] Add CoreSpotlight framework to ShareExtension target (optional)
- [ ] Add URL Scheme for deep linking

---

### 1. Add CoreSpotlight Framework (Required)

**For JourneyWallet target:**

1. Open `JourneyWallet.xcodeproj` in Xcode
2. Select **JourneyWallet** project in the navigator (blue icon)
3. Select **JourneyWallet** target (under TARGETS)
4. Go to **General** tab
5. Scroll to **Frameworks, Libraries, and Embedded Content**
6. Click **+** button
7. Search for `CoreSpotlight`
8. Select `CoreSpotlight.framework` and click **Add**

**For ShareExtension target (optional):**

If you want content saved via Share Extension to also be indexed:

1. Select **ShareExtension** target (under TARGETS)
2. Go to **General** tab
3. Scroll to **Frameworks, Libraries, and Embedded Content**
4. Click **+** and add `CoreSpotlight.framework`

---

### 2. Add URL Scheme for Deep Linking (Recommended)

This enables the app to open directly to specific content when user taps a Spotlight result.

1. Select **JourneyWallet** target
2. Go to **Info** tab
3. Expand **URL Types** section (at the bottom)
4. Click **+** to add a new URL type
5. Fill in:

| Field | Value |
|-------|-------|
| Identifier | `dev.mgorbatyuk.journeywallet` |
| URL Schemes | `journeywallet` |
| Role | Viewer |
| Icon | (leave empty) |

**Result:** App will handle URLs like `journeywallet://open?type=hotel&id=abc-123`

---

### Verification

After completing the manual steps:

1. Build the project (⌘B) - should succeed without errors
2. Check that `import CoreSpotlight` works in Swift files
3. Verify URL scheme in Info.plist:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>journeywallet</string>
           </array>
           <key>CFBundleURLName</key>
           <string>dev.mgorbatyuk.journeywallet</string>
       </dict>
   </array>
   ```

---

## Content to Index

### Priority Order

| Entity | Searchable Fields | Example User Search |
|--------|-------------------|---------------------|
| **Journey** | name, destination, notes | "My Paris trip" |
| **Hotel** | name, address, bookingReference | "Marriott booking" |
| **Transport** | carrier, flightNumber, departure/arrival | "Flight AA123" |
| **Place** | name, address, category | "Restaurant in Rome" |
| **CarRental** | company, carType, bookingReference | "Hertz rental" |
| **Note** | title, content | Quick note lookup |
| **Document** | displayName | "Passport scan" |

### Indexing Strategy

Each entity will be indexed with:
- **Unique Identifier**: `{entityType}:{entityId}:{journeyId}` (e.g., `hotel:abc-123:xyz-789`)
  - Journeys use: `journey:{journeyId}` (no parent journey)
  - Child entities use: `{type}:{entityId}:{journeyId}` for direct navigation
- **Domain Identifier**: `{bundleId}.{entityType}s` (dynamic based on build)
- **Title**: Entity name/title
- **Content Description**: Summary with dates, location, status
- **Keywords**: Searchable terms including booking references, addresses, categories
- **Related Identifier**: Link to parent journey for child entities

### Dev vs Prod Separation

Domain identifiers are built dynamically using the app's bundle identifier to keep dev and prod indexes separate:

| Build | Bundle ID | Example Domain |
|-------|-----------|----------------|
| **Dev** | `dev.mgorbatyuk.JourneyWallet.dev` | `dev.mgorbatyuk.JourneyWallet.dev.hotels` |
| **Prod** | `dev.mgorbatyuk.JourneyWallet` | `dev.mgorbatyuk.JourneyWallet.hotels` |

This ensures:
- Dev testing doesn't pollute prod Spotlight results
- Users don't see duplicate entries if both builds are installed
- Each build maintains its own independent index

---

## Implementation Plan

### Step 1: Create SpotlightService

**New file:** `JourneyWallet/Services/SpotlightService.swift`

A singleton service following the existing pattern (`AnalyticsService.shared`, `NotificationManager.shared`).

```swift
import CoreSpotlight
import MobileCoreServices
import os.log

@MainActor
final class SpotlightService {
    static let shared = SpotlightService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "SpotlightService")

    // MARK: - Domain Identifiers (Dynamic based on bundle ID)

    /// Base domain built from bundle identifier (different for dev/prod)
    private var baseDomain: String {
        Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.JourneyWallet"
    }

    /// Domain identifiers for each entity type
    private enum EntityType: String {
        case journey = "journeys"
        case hotel = "hotels"
        case transport = "transports"
        case place = "places"
        case carRental = "carrentals"
        case note = "notes"
        case document = "documents"
    }

    private func domain(for entityType: EntityType) -> String {
        "\(baseDomain).\(entityType.rawValue)"
    }

    // MARK: - Index Methods

    func indexJourney(_ journey: Journey) { ... }
    func indexHotel(_ hotel: Hotel, journeyId: UUID) { ... }
    func indexTransport(_ transport: Transport, journeyId: UUID) { ... }
    func indexPlace(_ place: PlaceToVisit, journeyId: UUID) { ... }
    func indexCarRental(_ carRental: CarRental, journeyId: UUID) { ... }
    func indexNote(_ note: Note, journeyId: UUID) { ... }
    func indexDocument(_ document: Document, journeyId: UUID) { ... }

    // MARK: - Remove Methods

    func removeFromIndex(identifier: String) { ... }
    func removeAllItemsForJourney(_ journeyId: UUID) { ... }

    // MARK: - Batch Operations

    func reindexAllContent() async { ... }

    /// Clear all indexes for current build (dev or prod)
    func clearAllIndexes() {
        // Only clears indexes for current bundle's domains
        for entityType in [EntityType.journey, .hotel, .transport, .place, .carRental, .note, .document] {
            CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domain(for: entityType)]) { error in
                if let error = error {
                    self.logger.error("Failed to clear \(entityType.rawValue) index: \(error.localizedDescription)")
                }
            }
        }
    }
}
```

**Key responsibilities:**
- Create `CSSearchableItem` objects with proper attributes
- Submit items to `CSSearchableIndex.default()`
- Handle index updates and deletions
- Batch re-indexing for initial setup or data restore

### Step 2: Create SpotlightIndexable Protocol

**New file:** `BusinessLogic/Models/SpotlightIndexable.swift`

```swift
import CoreSpotlight

/// Protocol for entities that can be indexed in Spotlight
protocol SpotlightIndexable {
    var spotlightEntityType: String { get }
    var spotlightEntityId: UUID { get }
    func createSearchableAttributeSet() -> CSSearchableItemAttributeSet
}

/// Helper to build unique identifiers with journeyId for deep linking
extension SpotlightIndexable {
    /// For child entities: "hotel:entityId:journeyId"
    func spotlightIdentifier(journeyId: UUID) -> String {
        "\(spotlightEntityType):\(spotlightEntityId.uuidString):\(journeyId.uuidString)"
    }
}

/// Special extension for Journey (no parent journeyId needed)
extension Journey: SpotlightIndexable {
    var spotlightEntityType: String { "journey" }
    var spotlightEntityId: UUID { id }

    /// For journeys: "journey:journeyId" (no parent)
    var spotlightIdentifier: String {
        "\(spotlightEntityType):\(id.uuidString)"
    }

    func createSearchableAttributeSet() -> CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = name
        attributes.contentDescription = "\(destination) • \(formattedDateRange)"
        attributes.keywords = [name, destination, notes].compactMap { $0 }
        return attributes
    }
}
```

**Extensions for child entities:**

```swift
extension Hotel: SpotlightIndexable {
    var spotlightEntityType: String { "hotel" }
    var spotlightEntityId: UUID { id }

    func createSearchableAttributeSet() -> CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = name
        attributes.contentDescription = "Check-in: \(checkInDate.formatted()) • \(numberOfNights) nights"
        attributes.keywords = [name, address, bookingReference, notes].compactMap { $0 }
        return attributes
    }
}

extension Transport: SpotlightIndexable {
    var spotlightEntityType: String { "transport" }
    var spotlightEntityId: UUID { id }
    // ... similar pattern
}

extension PlaceToVisit: SpotlightIndexable { ... }
extension CarRental: SpotlightIndexable { ... }
extension Note: SpotlightIndexable { ... }
extension Document: SpotlightIndexable { ... }
```

**Usage in SpotlightService:**

```swift
// Indexing a journey (no parent journeyId)
func indexJourney(_ journey: Journey) {
    let item = CSSearchableItem(
        uniqueIdentifier: journey.spotlightIdentifier,  // "journey:abc-123"
        domainIdentifier: domain(for: .journey),
        attributeSet: journey.createSearchableAttributeSet()
    )
    // ...
}

// Indexing a child entity (includes journeyId for deep linking)
func indexHotel(_ hotel: Hotel, journeyId: UUID) {
    let item = CSSearchableItem(
        uniqueIdentifier: hotel.spotlightIdentifier(journeyId: journeyId),  // "hotel:abc-123:xyz-789"
        domainIdentifier: domain(for: .hotel),
        attributeSet: hotel.createSearchableAttributeSet()
    )
    // ...
}
```

### Step 3: Hook into Repository CRUD Operations

**Modify repositories to call SpotlightService:**

Files to modify:
- `BusinessLogic/Database/Repositories/JourneysRepository.swift`
- `BusinessLogic/Database/Repositories/HotelsRepository.swift`
- `BusinessLogic/Database/Repositories/TransportsRepository.swift`
- `BusinessLogic/Database/Repositories/PlacesToVisitRepository.swift`
- `BusinessLogic/Database/Repositories/CarRentalsRepository.swift`
- `BusinessLogic/Database/Repositories/NotesRepository.swift`
- `BusinessLogic/Database/Repositories/DocumentsRepository.swift`

**Pattern for each repository:**

```swift
// In insert method
func insert(_ entity: Entity) -> Bool {
    // ... existing insert logic ...

    if success {
        Task { @MainActor in
            SpotlightService.shared.indexEntity(entity, journeyId: journeyId)
        }
    }
    return success
}

// In update method
func update(_ entity: Entity) -> Bool {
    // ... existing update logic ...

    if success {
        Task { @MainActor in
            SpotlightService.shared.indexEntity(entity, journeyId: journeyId)
        }
    }
    return success
}

// In delete method
func delete(id: UUID) -> Bool {
    // ... existing delete logic ...

    if success {
        Task { @MainActor in
            SpotlightService.shared.removeFromIndex(identifier: "entityType:\(id.uuidString)")
        }
    }
    return success
}
```

### Step 4: Handle Deep Linking from Spotlight

**Modify:** `JourneyWallet/JourneyWalletApp.swift`

Add handler for Spotlight search result taps:

```swift
@main
struct JourneyWalletApp: App {
    @State private var navigationPath = NavigationPath()
    @State private var selectedJourneyId: UUID?
    @State private var spotlightDestination: SpotlightDestination?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    handleSpotlightActivity(userActivity)
                }
        }
    }

    private func handleSpotlightActivity(_ activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }

        // Parse identifier
        // Format: "journey:journeyId" or "entityType:entityId:journeyId"
        let components = identifier.split(separator: ":")
        let entityType = String(components[0])

        switch entityType {
        case "journey":
            // Format: "journey:journeyId"
            guard components.count >= 2,
                  let journeyId = UUID(uuidString: String(components[1])) else { return }
            spotlightDestination = .journey(id: journeyId)

        case "hotel":
            // Format: "hotel:hotelId:journeyId"
            guard components.count >= 3,
                  let entityId = UUID(uuidString: String(components[1])),
                  let journeyId = UUID(uuidString: String(components[2])) else { return }
            spotlightDestination = .hotel(id: entityId, journeyId: journeyId)

        case "transport":
            guard components.count >= 3,
                  let entityId = UUID(uuidString: String(components[1])),
                  let journeyId = UUID(uuidString: String(components[2])) else { return }
            spotlightDestination = .transport(id: entityId, journeyId: journeyId)

        case "place":
            guard components.count >= 3,
                  let entityId = UUID(uuidString: String(components[1])),
                  let journeyId = UUID(uuidString: String(components[2])) else { return }
            spotlightDestination = .place(id: entityId, journeyId: journeyId)

        case "carrental":
            guard components.count >= 3,
                  let entityId = UUID(uuidString: String(components[1])),
                  let journeyId = UUID(uuidString: String(components[2])) else { return }
            spotlightDestination = .carRental(id: entityId, journeyId: journeyId)

        case "note":
            guard components.count >= 3,
                  let entityId = UUID(uuidString: String(components[1])),
                  let journeyId = UUID(uuidString: String(components[2])) else { return }
            spotlightDestination = .note(id: entityId, journeyId: journeyId)

        case "document":
            guard components.count >= 3,
                  let entityId = UUID(uuidString: String(components[1])),
                  let journeyId = UUID(uuidString: String(components[2])) else { return }
            spotlightDestination = .document(id: entityId, journeyId: journeyId)

        default:
            break
        }
    }
}

enum SpotlightDestination: Hashable {
    case journey(id: UUID)
    case hotel(id: UUID, journeyId: UUID)
    case transport(id: UUID, journeyId: UUID)
    case place(id: UUID, journeyId: UUID)
    case carRental(id: UUID, journeyId: UUID)
    case note(id: UUID, journeyId: UUID)
    case document(id: UUID, journeyId: UUID)
}
```

### Step 5: Initial Indexing

**Modify:** `JourneyWalletApp.swift`

Add one-time full index on first launch or app update:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // ... existing code ...

    // Index all content for Spotlight (runs once per app version)
    Task { @MainActor in
        await SpotlightService.shared.reindexIfNeeded()
    }

    return true
}
```

**In SpotlightService:**

```swift
private let indexedVersionKey = "spotlightIndexedAppVersion"

func reindexIfNeeded() async {
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let indexedVersion = UserDefaults.standard.string(forKey: indexedVersionKey)

    guard indexedVersion != currentVersion else {
        return // Already indexed for this version
    }

    await reindexAllContent()
    UserDefaults.standard.set(currentVersion, forKey: indexedVersionKey)
}

func reindexAllContent() async {
    // Clear existing indexes
    clearAllIndexes()

    // Re-index all journeys and their content
    let journeys = DatabaseManager.shared.journeysRepository?.fetchAll() ?? []
    for journey in journeys {
        indexJourney(journey)

        // Index child entities
        let hotels = DatabaseManager.shared.hotelsRepository?.fetchByJourneyId(journeyId: journey.id) ?? []
        hotels.forEach { indexHotel($0, journeyId: journey.id) }

        // ... repeat for other entity types
    }
}
```

### Step 6: Re-index After Data Restore

**Modify:** `BackupService.swift`

After restoring from backup, trigger full re-index:

```swift
func restoreFromiCloudBackup(_ backup: iCloudBackupInfo) async throws {
    // ... existing restore logic ...

    // Re-index all content for Spotlight
    await SpotlightService.shared.reindexAllContent()
}
```

### Step 7: Add Localization Strings

**Modify all `Localizable.strings` files:**

```
/* Spotlight Search */
"spotlight.journey.description" = "Journey to %@";
"spotlight.hotel.description" = "Hotel in %@";
"spotlight.transport.description" = "%@ from %@ to %@";
"spotlight.place.description" = "%@ in %@";
"spotlight.car_rental.description" = "Car rental from %@";
"spotlight.note.description" = "Note from %@";
"spotlight.document.description" = "Document: %@";

/* Spotlight Developer Settings */
"settings.developer.spotlight_section" = "Spotlight Search";
"settings.developer.reindex_spotlight" = "Reindex All Content";
"settings.developer.reindex_spotlight_hint" = "Rebuilds the Spotlight search index for all journeys and their content.";
"settings.developer.clear_spotlight_index" = "Clear Spotlight Index";
"settings.developer.clear_spotlight_confirm_title" = "Clear Spotlight Index?";
"settings.developer.clear_spotlight_confirm_message" = "This will remove all app content from system search. Content will be re-indexed automatically.";
"settings.developer.reindexing" = "Reindexing...";
"settings.developer.reindex_complete" = "Reindex complete";
```

### Step 8: Add Developer Settings Buttons

**Modify:** `JourneyWallet/UserSettings/UserSettingsView.swift`

Add Spotlight controls to the Developer section (visible when developer mode is enabled):

```swift
// Inside the Developer section, after existing buttons:

// MARK: - Spotlight Section

Section(header: Text(L("settings.developer.spotlight_section"))) {

    // Reindex All Content button
    Button(action: {
        Task {
            isReindexingSpotlight = true
            await SpotlightService.shared.reindexAllContent()
            isReindexingSpotlight = false
        }
    }) {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(L("settings.developer.reindex_spotlight"))
                    .foregroundColor(.primary)
                Text(L("settings.developer.reindex_spotlight_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isReindexingSpotlight {
                ProgressView()
            }
        }
    }
    .buttonStyle(.plain)
    .disabled(isReindexingSpotlight)

    // Clear Index button
    Button(action: {
        showClearSpotlightConfirmation = true
    }) {
        HStack {
            Image(systemName: "trash")
                .foregroundColor(.red)
            Text(L("settings.developer.clear_spotlight_index"))
                .foregroundColor(.red)
        }
    }
    .buttonStyle(.plain)
    .confirmationDialog(
        L("settings.developer.clear_spotlight_confirm_title"),
        isPresented: $showClearSpotlightConfirmation,
        titleVisibility: .visible
    ) {
        Button(L("Delete"), role: .destructive) {
            SpotlightService.shared.clearAllIndexes()
        }
        Button(L("Cancel"), role: .cancel) {}
    } message: {
        Text(L("settings.developer.clear_spotlight_confirm_message"))
    }
}
```

**Add state variables:**

```swift
@State private var isReindexingSpotlight = false
@State private var showClearSpotlightConfirmation = false
```

**Modify:** `JourneyWallet/UserSettings/UserSettingsViewModel.swift`

Add methods if needed for Spotlight operations (optional, can call SpotlightService directly from View).

---

## File Summary

| Action | File |
|--------|------|
| **Create** | `JourneyWallet/Services/SpotlightService.swift` |
| **Create** | `BusinessLogic/Models/SpotlightIndexable.swift` |
| Modify | `BusinessLogic/Database/Repositories/JourneysRepository.swift` |
| Modify | `BusinessLogic/Database/Repositories/HotelsRepository.swift` |
| Modify | `BusinessLogic/Database/Repositories/TransportsRepository.swift` |
| Modify | `BusinessLogic/Database/Repositories/PlacesToVisitRepository.swift` |
| Modify | `BusinessLogic/Database/Repositories/CarRentalsRepository.swift` |
| Modify | `BusinessLogic/Database/Repositories/NotesRepository.swift` |
| Modify | `BusinessLogic/Database/Repositories/DocumentsRepository.swift` |
| Modify | `JourneyWallet/JourneyWalletApp.swift` |
| Modify | `JourneyWallet/Services/BackupService.swift` |
| Modify | `JourneyWallet/UserSettings/UserSettingsView.swift` |
| Modify | `JourneyWallet/en.lproj/Localizable.strings` |
| Modify | `JourneyWallet/de.lproj/Localizable.strings` |
| Modify | `JourneyWallet/ru.lproj/Localizable.strings` |
| Modify | `JourneyWallet/tr.lproj/Localizable.strings` |
| Modify | `JourneyWallet/kk.lproj/Localizable.strings` |
| Modify | `JourneyWallet/uk.lproj/Localizable.strings` |

---

## Technical Details

### Spotlight Item Structure

```swift
// Domain is built dynamically from bundle identifier
let domainIdentifier = "\(Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.JourneyWallet").hotels"
// Dev:  "dev.mgorbatyuk.JourneyWallet.dev.hotels"
// Prod: "dev.mgorbatyuk.JourneyWallet.hotels"

// For child entities - includes journeyId for deep linking
let item = CSSearchableItem(
    uniqueIdentifier: "hotel:abc-123-def:xyz-789-ghi",  // hotel:hotelId:journeyId
    domainIdentifier: domainIdentifier,
    attributeSet: attributeSet
)
item.expirationDate = Date.distantFuture // Keep indexed indefinitely
```

### Attribute Set Configuration

```swift
let attributes = CSSearchableItemAttributeSet(contentType: .content)
attributes.title = "Grand Hotel Barcelona"
attributes.contentDescription = "Check-in: Jan 15, 2024 • 3 nights • Booking: HX7392"
attributes.keywords = ["Grand Hotel", "Barcelona", "HX7392", "Spain"]
attributes.thumbnailData = UIImage(systemName: "building.2")?.pngData()
attributes.relatedUniqueIdentifier = "journey:xyz-789-ghi"  // Links to parent journey
```

### Deep Link Identifier Format

```
Journeys (no parent):
  journey:{journeyId}

Child entities (with parent journeyId for navigation):
  {entityType}:{entityId}:{journeyId}

Examples:
- journey:550e8400-e29b-41d4-a716-446655440000
- hotel:6ba7b810-9dad-11d1-80b4-00c04fd430c8:550e8400-e29b-41d4-a716-446655440000
- transport:6ba7b811-9dad-11d1-80b4-00c04fd430c8:550e8400-e29b-41d4-a716-446655440000
- place:6ba7b812-9dad-11d1-80b4-00c04fd430c8:550e8400-e29b-41d4-a716-446655440000
```

### What Happens When User Taps Spotlight Result

1. **User searches** in Spotlight (swipe down on home screen)
2. **App content appears** in results (e.g., "Grand Hotel Barcelona")
3. **User taps** the result
4. **iOS launches app** and calls `onContinueUserActivity(CSSearchableItemActionType)`
5. **App parses identifier** (e.g., `hotel:abc-123:xyz-789`)
   - Entity type: `hotel`
   - Entity ID: `abc-123`
   - Journey ID: `xyz-789`
6. **App navigates directly** to `HotelDetailView(hotel: hotel, journeyId: journeyId)`

No database lookup needed - all required IDs are in the identifier.

---

## Testing

### Manual Testing

1. Add a journey with hotels, transports, places
2. Swipe down on home screen
3. Search for journey name, hotel name, booking reference
4. Verify items appear in search results
5. Tap result and verify app opens to correct screen

### Simulator Testing

Use `xcrun simctl` to trigger Spotlight indexing:

```bash
xcrun simctl spawn booted launchctl kickstart -k system/com.apple.spotlight.ImportAgent
```

### Debug Logging

Add logging to SpotlightService for development:

```swift
#if DEBUG
logger.debug("Indexed \(identifier) with title: \(title)")
#endif
```

---

## Considerations

### Performance

- Index operations are asynchronous and don't block UI
- Batch indexing uses `CSSearchableIndex.default().indexSearchableItems()`
- Consider throttling during bulk operations (data restore)

### Privacy

- Only index data stored locally
- No sensitive data in searchable attributes (no passwords, no full credit card numbers)
- Booking references are acceptable (partial/masked if needed)

### Localization

- Index items in user's current language
- Update indexes when user changes app language
- Use `L()` function for localized descriptions

### Data Consistency

- Always update index when data changes
- Remove from index when entity is deleted
- Re-index when journey is deleted (remove all child entities)

---

## Future Enhancements

1. **Siri Shortcuts Integration** - Allow users to create shortcuts for common actions
2. **Handoff Support** - Continue viewing entity on another device
3. **Proactive Suggestions** - Surface upcoming flights/hotels at relevant times
4. **Widget Integration** - Show indexed content in widgets
