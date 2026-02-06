# JWF-4: Trip Roadmap / Timeline

## What JWF-4 Requires

A **visual timeline** for trip planning with:
- Cities/waypoints as dots on a timeline
- Transport lines connecting the dots
- Attachable travel objects (hotels, places, etc.) to each stop
- Drag & drop reordering
- Tap to expand/collapse details
- Journey selector dropdown (reusing Tab 1 pattern)
- Replaces Reminders as Tab 2

---

## Data Model Design

**Two new tables are needed:**

### 1. `roadmap_stops` — Timeline waypoints (cities/places)

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `journey_id` | UUID | FK to journeys |
| `title` | String | City/place name (required) |
| `subtitle` | String? | Optional description |
| `arrival_date` | Date? | When arriving at this stop |
| `departure_date` | Date? | When leaving |
| `sort_order` | Int | For drag & drop reordering |
| `outgoing_transport_id` | UUID? | FK to `transports` — transport to next stop (the "line") |
| `notes` | String? | Free-form notes |
| `created_at` | Date | |
| `updated_at` | Date | |

### 2. `roadmap_stop_attachments` — Links travel objects to stops

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key |
| `roadmap_stop_id` | UUID | FK to roadmap_stops |
| `entity_type` | String | "hotel", "carRental", "placeToVisit", "idea", "expense" |
| `entity_id` | UUID | FK to the actual entity |
| `created_at` | Date | |

**Why not reuse PlaceToVisit?** PlaceToVisit is a "bookmark" entity (restaurant, museum). Roadmap stops represent **itinerary waypoints** (cities/regions) that *contain* other travel objects. They're structurally different — stops are containers, PlaceToVisit items go *inside* stops.

**The `outgoing_transport_id` design:** Each stop optionally points to a Transport entity that represents "how you get from this stop to the next." When dragged to reorder, the outgoing transport stays with its origin stop, which is conceptually correct ("from Paris, take a train...").

---

## Visual Concept

```
[Journey Selector Dropdown]
─────────────────────────────
     ● Paris                    ← dot (tap to expand)
     │  🏨 Hotel Le Marais      ← attached objects (shown on expand)
     │  📍 Eiffel Tower
     │
     ┊  🚄 TGV #1234           ← outgoing transport (on the line)
     │
     ● Lyon                     ← next dot
     │  🏨 Lyon Marriott
     │
     ┊  🚗 Car Rental           ← outgoing transport
     │
     ● Nice                     ← final dot
     │  🏨 Promenade Hotel
     │  📍 Beach Walk
─────────────────────────────
          [+ Add Stop]
```

**Collapsed state:** Only dots with short titles and date range.
**Expanded state (on tap):** Shows attached objects and transport details.

---

## Files to Create / Modify

### New Files (~12 files)

**Models:**
- `BusinessLogic/Models/RoadmapStop.swift` — Data model
- `BusinessLogic/Models/RoadmapStopAttachment.swift` — Junction model

**Database:**
- `BusinessLogic/Database/Migrations/Migration_YYYYMMDD_RoadmapTables.swift` — Create both tables
- `BusinessLogic/Database/Repositories/RoadmapStopsRepository.swift` — CRUD + reorder
- `BusinessLogic/Database/Repositories/RoadmapStopAttachmentsRepository.swift` — CRUD for links

**Views & ViewModels:**
- `JourneyWallet/Roadmap/RoadmapTimelineView.swift` — Main tab view with journey selector
- `JourneyWallet/Roadmap/RoadmapTimelineViewModel.swift` — Data loading, reorder logic
- `JourneyWallet/Roadmap/RoadmapStopRow.swift` — Expandable stop with dot/line UI
- `JourneyWallet/Roadmap/RoadmapStopFormView.swift` — Add/edit stop
- `JourneyWallet/Roadmap/RoadmapAttachmentPicker.swift` — Pick existing travel objects to attach
- `JourneyWallet/Roadmap/RoadmapConnectionView.swift` — Transport line between stops

**Shared UI Components:**
- `JourneyWallet/Roadmap/RoadmapAttachmentBanner.swift` — Reusable banner showing "Attached to [Stop Name]" with detach button, used inside detail views

### Modified Files

- **`DatabaseManager.swift`** — Add repositories + increment migration version (9)
- **`MainTabView.swift`** — Replace Tab 2 (Reminders → Roadmap), shift Reminders to Tab 3
- **Localization files** (6 `Localizable.strings`) — New keys for roadmap UI
- **`TransportDetailViewModel.swift`** — Add roadmap attachment lookup + detach method
- **`TransportDetailView.swift`** — Add `RoadmapAttachmentBanner` section
- **`HotelDetailViewModel.swift`** — Add roadmap attachment lookup + detach method
- **`HotelDetailView.swift`** — Add `RoadmapAttachmentBanner` section
- **`CarRentalDetailViewModel.swift`** — Add roadmap attachment lookup + detach method
- **`CarRentalDetailView.swift`** — Add `RoadmapAttachmentBanner` section
- **`PlaceToVisitDetailViewModel.swift`** — Add roadmap attachment lookup + detach method
- **`PlaceToVisitDetailView.swift`** — Add `RoadmapAttachmentBanner` section
- **`IdeaDetailViewModel.swift`** — Add roadmap attachment lookup + detach method
- **`IdeaDetailView.swift`** — Add `RoadmapAttachmentBanner` section

---

## Key Implementation Details

### Drag & Drop Reordering

Use SwiftUI's `.onMove` modifier on a `List`/`ForEach` to handle reorder, then persist new `sort_order` values:

```swift
ForEach(viewModel.stops) { stop in
    RoadmapStopRow(stop: stop, ...)
}
.onMove { source, destination in
    viewModel.moveStops(from: source, to: destination)
}
```

The ViewModel updates `sort_order` for all affected stops in the repository.

### Timeline Rendering

A custom vertical timeline using `VStack` with:
- Circle shapes for dots (filled = visited, outlined = upcoming)
- Vertical lines (dashed `Rectangle` or `Path`) between dots
- Transport info overlaid on lines
- Expand/collapse using `@State` + `.animation`

### Attachment Picker

When attaching objects to a stop, show a sheet listing all journey's entities (hotels, transports, places, ideas) that aren't already attached to another stop. Filter by `journeyId`, exclude already-attached IDs.

### Journey Selector Reuse

Directly reuse `JourneySelectorView` at the top of `RoadmapTimelineView`, same pattern as `JourneyDetailView` — persist selection in UserDefaults with a separate key.

### Database Migration (version 9)

Single migration file creates both `roadmap_stops` and `roadmap_stop_attachments` tables with proper indexes on `journey_id` and `roadmap_stop_id`.

### Timeline Attachment Banner in Detail Views

When a travel object (hotel, transport, car rental, place, idea) is opened from the Journey View (Tab 1), the detail view should display a **banner/block** indicating whether it is attached to a roadmap timeline stop, and provide a **detach button**.

#### Lookup Logic

Each detail ViewModel gets a new dependency on `RoadmapStopAttachmentsRepository` and loads the attachment on init:

```swift
// In EntityDetailViewModel
private let attachmentsRepository: RoadmapStopAttachmentsRepository?
private let stopsRepository: RoadmapStopsRepository?

var roadmapAttachment: RoadmapStopAttachment?  // nil = not attached
var attachedStopTitle: String?                  // resolved stop name for display

func loadRoadmapAttachment() {
    let entityType = "hotel" // or "transport", "carRental", etc.
    roadmapAttachment = attachmentsRepository?.fetchByEntityId(
        entityId: entity.id, entityType: entityType
    )
    if let stopId = roadmapAttachment?.roadmapStopId {
        attachedStopTitle = stopsRepository?.fetchById(id: stopId)?.title
    }
}

func detachFromRoadmap() {
    guard let attachment = roadmapAttachment else { return }
    _ = attachmentsRepository?.delete(id: attachment.id)
    roadmapAttachment = nil
    attachedStopTitle = nil
}
```

#### Repository Method Needed

`RoadmapStopAttachmentsRepository` needs a query method:

```swift
func fetchByEntityId(entityId: UUID, entityType: String) -> RoadmapStopAttachment?
```

This queries `roadmap_stop_attachments` where `entity_id = ? AND entity_type = ?`.

#### Reusable Banner Component — `RoadmapAttachmentBanner`

A shared SwiftUI view used across all detail views:

```swift
struct RoadmapAttachmentBanner: View {
    let stopTitle: String
    let onDetach: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "map")
            VStack(alignment: .leading) {
                Text(L("roadmap.attached_to"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(stopTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
            Button(role: .destructive, action: onDetach) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
```

#### Usage in Detail Views

Each detail view adds the banner conditionally near the top of the scroll content:

```swift
// Inside EntityDetailView body
if let stopTitle = viewModel.attachedStopTitle {
    RoadmapAttachmentBanner(
        stopTitle: stopTitle,
        onDetach: { viewModel.detachFromRoadmap() }
    )
    .padding(.horizontal)
}
```

The banner only appears when the object is attached to a roadmap stop. The detach button removes the `roadmap_stop_attachments` row and hides the banner immediately.

---

## Risks & Considerations

1. **Drag & drop on complex timeline UI** — Standard `List.onMove` works well for simple lists but may need custom `DragGesture` for the visual timeline. Start with `List.onMove`, refine later.
2. **Orphaned attachments** — When a transport/hotel/place is deleted, its attachment links should be cleaned up. Add cascade logic in existing delete methods or use a cleanup pass.
3. **Reminders tab displacement** — Moving Reminders from Tab 2 to Tab 3 changes user muscle memory. Consider keeping Reminders accessible (e.g., as Tab 4, shifting Settings to Tab 5, or merging into the journey detail screen).
4. **Performance** — Loading all attachments for all stops requires multiple repository calls. Consider a single query that joins stops + attachments for efficiency.
