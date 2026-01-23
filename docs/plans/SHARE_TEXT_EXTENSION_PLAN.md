# Share Text & Links Extension Plan

## Overview

Extend the existing Share Extension to support sharing text and URLs from other apps. Users can share booking confirmations, links, notes, or any text and choose what type of entity to create in Journey Wallet.

### User Flow

1. User selects text or copies a link in another app (Safari, Mail, Notes, etc.)
2. User taps Share button
3. User selects "Journey Wallet" from Share sheet
4. Share Extension UI appears with:
   - Shared content preview (text/URL)
   - Entity type picker: Transport, Hotel, Car Rental, Note, Place to Visit
   - Journey selector
   - Entity-specific form fields (based on selected type)
5. User fills in details and saves
6. Entity is created in the selected journey

---

## Supported Share Types

| Share Type | Example Source | Use Case |
|------------|----------------|----------|
| Plain Text | Email body, Notes | Booking reference, notes |
| URL | Safari, Mail links | Booking links, place links |
| URL + Text | Safari selection | Link with description |

---

## Entity Type Options

### 1. Transport Reference
Create a new transport entry with shared content as booking reference or notes.

**Pre-filled fields:**
- Booking reference (if text looks like a reference code)
- Notes (shared text/URL)

**Required user input:**
- Transport type (flight, train, bus, ferry, transfer)
- Route (from → to)
- Date/time

### 2. Hotel Reference
Create a new hotel entry with shared content as booking reference or notes.

**Pre-filled fields:**
- Booking reference (if text looks like a reference code)
- Notes (shared text/URL)

**Required user input:**
- Hotel name
- Check-in / Check-out dates

### 3. Car Rental Reference
Create a new car rental entry with shared content as booking reference or notes.

**Pre-filled fields:**
- Booking reference (if text looks like a reference code)
- Notes (shared text/URL)

**Required user input:**
- Rental company
- Pickup location
- Pickup / Return dates

### 4. Note
Create a journey note with shared content.

**Pre-filled fields:**
- Title (first line of text or URL domain)
- Content (full shared text/URL)

**Required user input:**
- None (can save immediately)

### 5. Place to Visit
Create a place to visit entry.

**Pre-filled fields:**
- Name (from URL title or first line)
- Notes (shared URL/text)

**Required user input:**
- Category (restaurant, attraction, museum, shopping, nature, other)

---

## UI Design

### Main Screen

```
┌─────────────────────────────────────┐
│ ← Cancel    Save to Journey   Save  │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 📋 Shared Content             │  │
│  │ "Booking ref: ABC123          │  │
│  │  Flight to Paris on Jan 25"   │  │
│  └───────────────────────────────┘  │
│                                     │
│  What is this?                      │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ ✈️  │ │ 🏨  │ │ 🚗  │           │
│  │Trans│ │Hotel│ │ Car │           │
│  └─────┘ └─────┘ └─────┘           │
│  ┌─────┐ ┌─────┐                   │
│  │ 📝  │ │ 📍  │                   │
│  │Note │ │Place│                   │
│  └─────┘ └─────┘                   │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Add to Journey                     │
│  ┌───────────────────────────────┐  │
│  │ 🧳 Trip to Paris      ▼       │  │
│  └───────────────────────────────┘  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  [Entity-specific form fields]      │
│                                     │
└─────────────────────────────────────┘
```

### Entity-Specific Forms

#### Transport Form
```
Transport Type: [Flight ▼]
From: [_____________]
To:   [_____________]
Date: [_____________]
Time: [_____________]
Booking Ref: [ABC123_____] (pre-filled)
Notes: [Full shared text]
```

#### Hotel Form
```
Hotel Name: [_____________]
Check-in:   [_____________]
Check-out:  [_____________]
Booking Ref: [_____________]
Notes: [Full shared text]
```

#### Car Rental Form
```
Company:    [_____________]
Pickup:     [_____________]
Return:     [_____________]
Pickup Date: [_____________]
Return Date: [_____________]
Booking Ref: [_____________]
Notes: [Full shared text]
```

#### Note Form
```
Title:   [First line_____] (pre-filled)
Content: [Full shared text] (pre-filled)
```

#### Place Form
```
Name:     [_____________]
Category: [Restaurant ▼]
Notes:    [Full shared text]
Planned Date: [Optional____]
```

---

## Technical Implementation

### Phase 1: Update Info.plist for Text/URL Support

Update `ShareExtension/Info.plist` to accept text and URLs:

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <!-- Existing file support -->
    <key>NSExtensionActivationSupportsFileWithMaxCount</key>
    <integer>10</integer>
    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
    <integer>10</integer>
    <!-- New: Text and URL support -->
    <key>NSExtensionActivationSupportsText</key>
    <true/>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
</dict>
```

### Phase 2: Update ShareViewController

Modify `ShareViewController.swift` to detect and extract:
- `kUTTypeURL` - shared URLs
- `kUTTypePlainText` - shared text
- Existing file types

```swift
enum SharedContentType {
    case files([URL])
    case text(String)
    case url(URL, title: String?)
    case urlWithText(URL, String)
}
```

### Phase 3: Create Entity Type Selector

New SwiftUI component for selecting entity type:

```swift
enum ShareEntityType: String, CaseIterable {
    case transport
    case hotel
    case carRental
    case note
    case place

    var icon: String { ... }
    var title: String { ... }
}

struct EntityTypePicker: View {
    @Binding var selected: ShareEntityType
    // Grid of selectable entity types
}
```

### Phase 4: Create Entity-Specific Forms

Create form views for each entity type:

```
ShareExtension/
├── Forms/
│   ├── ShareTransportForm.swift
│   ├── ShareHotelForm.swift
│   ├── ShareCarRentalForm.swift
│   ├── ShareNoteForm.swift
│   └── SharePlaceForm.swift
```

Each form:
- Receives shared content
- Pre-fills relevant fields
- Validates required fields
- Returns entity data for saving

### Phase 5: Update ShareViewModel

Extend `ShareViewModel` to handle:
- Different content types (files vs text/URL)
- Different entity types
- Saving to appropriate repositories

```swift
class ShareViewModel: ObservableObject {
    @Published var contentType: SharedContentType
    @Published var entityType: ShareEntityType = .note
    @Published var sharedText: String = ""
    @Published var sharedURL: URL?

    // Entity-specific data
    @Published var transportData: TransportFormData?
    @Published var hotelData: HotelFormData?
    @Published var carRentalData: CarRentalFormData?
    @Published var noteData: NoteFormData?
    @Published var placeData: PlaceFormData?

    func save() {
        switch entityType {
        case .transport: saveTransport()
        case .hotel: saveHotel()
        case .carRental: saveCarRental()
        case .note: saveNote()
        case .place: savePlace()
        }
    }
}
```

### Phase 6: Update ShareView

Modify main `ShareView.swift` to:
1. Show content preview
2. Display entity type picker (for text/URL only)
3. Show appropriate form based on selection
4. Handle both file and text/URL flows

```swift
struct ShareView: View {
    var body: some View {
        switch viewModel.contentType {
        case .files:
            // Existing file sharing flow
            FileShareView(viewModel: viewModel)
        case .text, .url, .urlWithText:
            // New text/URL sharing flow
            TextShareView(viewModel: viewModel)
        }
    }
}
```

### Phase 7: Smart Content Detection

Implement heuristics to suggest entity type:

```swift
struct ContentAnalyzer {
    static func suggestEntityType(for text: String) -> ShareEntityType {
        let lowercased = text.lowercased()

        // Flight keywords
        if lowercased.contains("flight") ||
           lowercased.contains("boarding") ||
           lowercased.contains("airline") {
            return .transport
        }

        // Hotel keywords
        if lowercased.contains("hotel") ||
           lowercased.contains("check-in") ||
           lowercased.contains("reservation") {
            return .hotel
        }

        // Car rental keywords
        if lowercased.contains("car rental") ||
           lowercased.contains("vehicle") ||
           lowercased.contains("pickup") {
            return .carRental
        }

        // URL might be a place
        if text.hasPrefix("http") {
            return .place
        }

        // Default to note
        return .note
    }

    static func extractBookingReference(from text: String) -> String? {
        // Regex patterns for common booking reference formats
        // e.g., ABC123, 12345678, XX-1234-YY
    }
}
```

---

## Database Requirements

No schema changes needed. Uses existing tables:
- `transports`
- `hotels`
- `car_rentals`
- `notes`
- `places_to_visit`

---

## Localization

### New Keys Required

```
// Entity type picker
"share.entity_type.title" = "What is this?";
"share.entity_type.transport" = "Transport";
"share.entity_type.hotel" = "Hotel";
"share.entity_type.car_rental" = "Car Rental";
"share.entity_type.note" = "Note";
"share.entity_type.place" = "Place to Visit";

// Content preview
"share.content_preview" = "Shared Content";
"share.content_url" = "Link";
"share.content_text" = "Text";

// Form labels
"share.form.transport_type" = "Transport Type";
"share.form.from" = "From";
"share.form.to" = "To";
"share.form.date" = "Date";
"share.form.time" = "Time";
"share.form.booking_ref" = "Booking Reference";
"share.form.hotel_name" = "Hotel Name";
"share.form.check_in" = "Check-in";
"share.form.check_out" = "Check-out";
"share.form.company" = "Rental Company";
"share.form.pickup_location" = "Pickup Location";
"share.form.return_location" = "Return Location";
"share.form.note_title" = "Title";
"share.form.note_content" = "Content";
"share.form.place_name" = "Place Name";
"share.form.place_category" = "Category";
"share.form.planned_date" = "Planned Date";
```

---

## File Structure

```
ShareExtension/
├── Info.plist                    # Updated with text/URL support
├── ShareExtension.entitlements
├── ShareExtensionDebug.entitlements
├── ShareViewController.swift     # Updated content detection
├── ShareView.swift               # Branching logic for content type
├── ShareViewModel.swift          # Extended with entity handling
├── Models/
│   ├── SharedContentType.swift
│   ├── ShareEntityType.swift
│   └── FormData/
│       ├── TransportFormData.swift
│       ├── HotelFormData.swift
│       ├── CarRentalFormData.swift
│       ├── NoteFormData.swift
│       └── PlaceFormData.swift
├── Views/
│   ├── ContentPreviewView.swift
│   ├── EntityTypePicker.swift
│   ├── FileShareView.swift       # Existing file flow
│   └── TextShareView.swift       # New text/URL flow
└── Forms/
    ├── ShareTransportForm.swift
    ├── ShareHotelForm.swift
    ├── ShareCarRentalForm.swift
    ├── ShareNoteForm.swift
    └── SharePlaceForm.swift
```

---

## Implementation Order

1. **Phase 1** - Update Info.plist for text/URL support
2. **Phase 2** - Update ShareViewController to detect content types
3. **Phase 3** - Create SharedContentType and ShareEntityType models
4. **Phase 4** - Create EntityTypePicker UI component
5. **Phase 5** - Create ContentPreviewView
6. **Phase 6** - Create form data models
7. **Phase 7** - Create entity-specific form views
8. **Phase 8** - Update ShareViewModel with entity handling
9. **Phase 9** - Update ShareView with branching logic
10. **Phase 10** - Implement smart content detection
11. **Phase 11** - Add localization keys
12. **Phase 12** - Testing

---

## Testing Checklist

### Text Sharing
- [ ] Share plain text from Notes app
- [ ] Share selected text from Safari
- [ ] Share text from email body

### URL Sharing
- [ ] Share link from Safari
- [ ] Share link from Mail
- [ ] Share link from other apps

### Entity Creation
- [ ] Create Transport from shared text
- [ ] Create Hotel from shared text
- [ ] Create Car Rental from shared text
- [ ] Create Note from shared text
- [ ] Create Place from shared URL

### Smart Detection
- [ ] Flight-related text suggests Transport
- [ ] Hotel-related text suggests Hotel
- [ ] Car rental text suggests Car Rental
- [ ] URLs suggest Place
- [ ] Generic text suggests Note

### Edge Cases
- [ ] Very long text
- [ ] Text with special characters
- [ ] Invalid URLs
- [ ] Empty content handling

---

## Future Enhancements

1. **URL Metadata Fetching** - Fetch page title and description from URLs
2. **Booking Email Parsing** - Parse common booking email formats automatically
3. **OCR for Screenshots** - Extract text from shared screenshots
4. **Multiple Entity Creation** - Parse email with flight + hotel and create both
5. **Templates** - Remember frequently used entity configurations
