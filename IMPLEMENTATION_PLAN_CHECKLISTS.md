# Checklist Feature Implementation Plan

## Overview

Add a Checklist functionality to Journey Wallet that allows users to create multiple named checklists per journey, each containing multiple items. Checklists are displayed as the first section on the Journey Detail page.

## Data Model

### Checklist Model (Parent)

```swift
struct Checklist: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var name: String
    var sortingOrder: Int
    let createdAt: Date
    var updatedAt: Date
}
```

**Fields:**
- `id` - Unique identifier (UUID)
- `journeyId` - Foreign key to Journey (UUID)
- `name` - Checklist name (String, required) e.g., "Packing", "Documents", "Before departure"
- `sortingOrder` - Custom sorting position (Int, default: 0)
- `createdAt` - Creation timestamp (Date)
- `updatedAt` - Last modification timestamp (Date)

### ChecklistItem Model (Child)

```swift
struct ChecklistItem: Codable, Identifiable, Equatable {
    let id: UUID
    let checklistId: UUID
    var name: String
    var isChecked: Bool
    var sortingOrder: Int
    let createdAt: Date
    var updatedAt: Date
}
```

**Fields:**
- `id` - Unique identifier (UUID)
- `checklistId` - Foreign key to Checklist (UUID)
- `name` - Item text (String, required)
- `isChecked` - Completion status (Bool, default: false)
- `sortingOrder` - Custom sorting position (Int, default: 0)
- `createdAt` - Creation timestamp (Date)
- `updatedAt` - Last modification timestamp (Date)

### Relationships

```
Journey (1) ──── (*) Checklist (1) ──── (*) ChecklistItem
```

## Implementation Tasks

### Phase 1: Database Layer

#### 1.1 Create Checklist Model
- **File:** `BusinessLogic/Models/Checklist.swift`
- Define struct with all fields
- Add convenience initializer for creating new checklists

#### 1.2 Create ChecklistItem Model
- **File:** `BusinessLogic/Models/ChecklistItem.swift`
- Define struct with all fields
- Add convenience initializer for creating new items
- Add computed property `statusIcon` for UI

#### 1.3 Create Database Migration
- **File:** `BusinessLogic/Database/Migrations/Migration_20260124_Checklists.swift`
- Create `checklists` table with columns:
  - `id` (TEXT, PRIMARY KEY)
  - `journey_id` (TEXT, NOT NULL, indexed)
  - `name` (TEXT, NOT NULL)
  - `sorting_order` (INTEGER, NOT NULL, default 0)
  - `created_at` (TEXT, NOT NULL)
  - `updated_at` (TEXT, NOT NULL)
- Create `checklist_items` table with columns:
  - `id` (TEXT, PRIMARY KEY)
  - `checklist_id` (TEXT, NOT NULL, indexed)
  - `name` (TEXT, NOT NULL)
  - `is_checked` (INTEGER, NOT NULL, default 0)
  - `sorting_order` (INTEGER, NOT NULL, default 0)
  - `created_at` (TEXT, NOT NULL)
  - `updated_at` (TEXT, NOT NULL)
- Add indices on foreign keys for efficient queries

#### 1.4 Create ChecklistsRepository
- **File:** `BusinessLogic/Database/Repositories/ChecklistsRepository.swift`
- Methods:
  - `fetchByJourneyId(journeyId: UUID) -> [Checklist]` (ordered by sortingOrder)
  - `fetchById(id: UUID) -> Checklist?`
  - `insert(_ checklist: Checklist) -> Bool`
  - `update(_ checklist: Checklist) -> Bool`
  - `delete(id: UUID) -> Bool`
  - `deleteByJourneyId(journeyId: UUID) -> Bool`
  - `countByJourneyId(journeyId: UUID) -> Int`
  - `getNextSortingOrder(journeyId: UUID) -> Int` (for new checklists)
  - `updateSortingOrders(_ checklists: [Checklist]) -> Bool` (for reordering)

#### 1.5 Create ChecklistItemsRepository
- **File:** `BusinessLogic/Database/Repositories/ChecklistItemsRepository.swift`
- Methods:
  - `fetchByChecklistId(checklistId: UUID) -> [ChecklistItem]` (ordered by sortingOrder)
  - `fetchById(id: UUID) -> ChecklistItem?`
  - `insert(_ item: ChecklistItem) -> Bool`
  - `update(_ item: ChecklistItem) -> Bool`
  - `delete(id: UUID) -> Bool`
  - `deleteByChecklistId(checklistId: UUID) -> Bool`
  - `countByChecklistId(checklistId: UUID) -> Int`
  - `countCheckedByChecklistId(checklistId: UUID) -> Int`
  - `toggleChecked(id: UUID) -> Bool`
  - `countTotalByJourneyId(journeyId: UUID) -> Int` (for aggregate progress)
  - `countCheckedByJourneyId(journeyId: UUID) -> Int` (for aggregate progress)
  - `getNextSortingOrder(checklistId: UUID) -> Int` (for new items)
  - `updateSortingOrders(_ items: [ChecklistItem]) -> Bool` (for reordering)

#### 1.6 Register in DatabaseManager
- **File:** `BusinessLogic/Database/DatabaseManager.swift`
- Add `checklistsRepository` property
- Add `checklistItemsRepository` property
- Increment `latestVersion` to 7
- Register migration in `migrateIfNeeded()`
- Initialize repositories in `initializeRepositories()`

### Phase 2: UI Layer - Checklists List (per Journey)

#### 2.1 Create ChecklistsListViewModel
- **File:** `JourneyWallet/Checklist/ChecklistsListViewModel.swift`
- Properties:
  - `checklists: [Checklist]`
  - `checklistProgress: [UUID: (checked: Int, total: Int)]` (progress per checklist)
  - `isLoading: Bool`
  - `showAddChecklistSheet: Bool`
  - `checklistToEdit: Checklist?`
- Methods:
  - `loadData()`
  - `addChecklist(name: String)`
  - `updateChecklist(_ checklist: Checklist)`
  - `deleteChecklist(_ checklist: Checklist)`
  - `getProgress(for checklistId: UUID) -> (checked: Int, total: Int)`
  - `moveChecklist(from: IndexSet, to: Int)` (for drag-to-reorder)
- Computed:
  - `totalProgress: (checked: Int, total: Int)` (aggregate across all checklists)

#### 2.2 Create ChecklistsListView
- **File:** `JourneyWallet/Checklist/ChecklistsListView.swift`
- Shows all checklists for a journey (ordered by sortingOrder)
- Each row displays:
  - Checklist name
  - Progress indicator (e.g., "3/8")
  - Progress bar
- Tap to navigate to ChecklistDetailView
- Swipe actions: Edit name, Delete
- **Reordering:** Use `.draggable()` and `.dropDestination()` modifiers for direct long-press drag reordering (no Edit mode required)
- Add button in toolbar
- Empty state when no checklists

#### 2.3 Create ChecklistRow
- **File:** `JourneyWallet/Checklist/ChecklistRow.swift`
- Checklist name
- Progress text (e.g., "5/10 completed")
- Mini progress bar
- Chevron for navigation

#### 2.4 Create ChecklistFormView
- **File:** `JourneyWallet/Checklist/ChecklistFormView.swift`
- Simple form with:
  - Name text field (required)
  - Save/Cancel buttons
- Used for both Add and Edit checklist

### Phase 3: UI Layer - Checklist Detail (Items)

#### 3.1 Create ChecklistDetailViewModel
- **File:** `JourneyWallet/Checklist/ChecklistDetailViewModel.swift`
- Properties:
  - `checklist: Checklist`
  - `items: [ChecklistItem]`
  - `filteredItems: [ChecklistItem]`
  - `selectedFilter: ChecklistItemFilter` (all, pending, completed)
  - `isLoading: Bool`
  - `showAddItemSheet: Bool`
  - `itemToEdit: ChecklistItem?`
  - `showMoveCheckedConfirmation: Bool` (for confirmation alert)
- Methods:
  - `loadData()`
  - `toggleItem(_ item: ChecklistItem)`
  - `addItem(name: String)`
  - `updateItem(_ item: ChecklistItem)`
  - `deleteItem(_ item: ChecklistItem)`
  - `updateChecklist(_ checklist: Checklist)`
  - `deleteChecklist() -> Bool`
  - `moveItem(from: IndexSet, to: Int)` (for drag-to-reorder)
  - `moveCheckedItemsToEnd()` (reorders all checked items to bottom, updates sortingOrder)
- Computed:
  - `progress: (checked: Int, total: Int)`
  - `progressPercentage: Double`
  - `hasCheckedItems: Bool` (to enable/disable the move button)

#### 3.2 Create ChecklistItemFilter Enum
- **File:** `JourneyWallet/Checklist/ChecklistItemFilter.swift`
- Cases: `all`, `pending`, `completed`
- Property: `displayName` using localization

#### 3.3 Create ChecklistDetailView
- **File:** `JourneyWallet/Checklist/ChecklistDetailView.swift`
- Navigation title: checklist name
- Filter chips (All, Pending, Completed)
- Progress bar with completion stats
- List of items (ordered by sortingOrder) with:
  - Checkbox toggle (tap to complete/uncomplete)
  - Item name (strikethrough when checked)
  - Swipe actions: Edit, Delete
  - **Reordering:** Use `.draggable()` and `.dropDestination()` modifiers for direct long-press drag reordering (no Edit mode required)
- Empty state when no items
- Toolbar items:
  - Add item button (+)
  - Menu (⋯) with options:
    - Edit checklist name
    - **"Move completed to end"** - disabled if no checked items, shows confirmation alert
- Confirmation alert for "Move completed to end":
  - Title: "Move Completed Items"
  - Message: "All checked items will be moved to the end of the list. This action cannot be undone."
  - Buttons: "Cancel" / "Move" (destructive style)

#### 3.4 Create ChecklistItemRow
- **File:** `JourneyWallet/Checklist/ChecklistItemRow.swift`
- Checkbox icon (circle/checkmark.circle.fill)
- Item name with strikethrough when checked
- Tap anywhere to toggle

#### 3.5 Create ChecklistItemFormView
- **File:** `JourneyWallet/Checklist/ChecklistItemFormView.swift`
- Simple form with:
  - Name text field (required)
  - Save/Cancel buttons
- Used for both Add and Edit item

### Phase 4: Integration with Journey Detail

#### 4.1 Update JourneyDetailViewModel
- **File:** `JourneyWallet/JourneyDetail/JourneyDetailViewModel.swift`
- Add properties:
  - `checklists: [Checklist]`
  - `checklistsTotalProgress: (checked: Int, total: Int)`
- Add methods:
  - `loadChecklists()`
- Update `loadAllData()` to include checklists

#### 4.2 Update JourneyDetailView
- **File:** `JourneyWallet/JourneyDetail/JourneyDetailView.swift`
- Add Checklists section as FIRST section (before Transport)
- Section includes:
  - Header with icon, title "Checklists", total progress (e.g., "12/25")
  - Preview of first 3 checklists with their individual progress
  - "See All" link to ChecklistsListView
- Add navigation destination for ChecklistsListView
- Add "Checklist" option to floating action button menu (creates new checklist)

### Phase 5: Localization

#### 5.1 Add Localization Keys
Update all `Localizable.strings` files:

**English (en.lproj):**
```
// Checklists (list of checklists)
"checklists.title" = "Checklists";
"checklists.add" = "New Checklist";
"checklists.edit" = "Edit Checklist";
"checklists.empty" = "No checklists";
"checklists.empty.description" = "Create checklists to track your tasks";
"checklists.name" = "Checklist name";
"checklists.name.placeholder" = "e.g., Packing, Documents";
"checklists.delete.confirm" = "Delete this checklist and all its items?";
"checklists.progress" = "%d of %d";

// Checklist items
"checklist.items.title" = "Items";
"checklist.items.add" = "Add Item";
"checklist.items.edit" = "Edit Item";
"checklist.items.empty" = "No items";
"checklist.items.empty.description" = "Add items to this checklist";
"checklist.items.progress" = "%d of %d completed";
"checklist.items.filter.all" = "All";
"checklist.items.filter.pending" = "Pending";
"checklist.items.filter.completed" = "Completed";
"checklist.items.name" = "Item name";
"checklist.items.name.placeholder" = "Enter item name";
"checklist.items.delete.confirm" = "Delete this item?";

// Move completed items action
"checklist.items.move_completed" = "Move completed to end";
"checklist.items.move_completed.title" = "Move Completed Items";
"checklist.items.move_completed.message" = "All checked items will be moved to the end of the list. This action cannot be undone.";
"checklist.items.move_completed.cancel" = "Cancel";
"checklist.items.move_completed.confirm" = "Move";
```

**Other languages:** Russian (ru), Kazakh (kk), Turkish (tr), German (de), Ukrainian (uk)

### Phase 6: Analytics

#### 6.1 Add Analytics Events
- `checklists_list_screen` - Screen view (list of checklists)
- `checklist_detail_screen` - Screen view (single checklist with items)
- `checklist_created` - New checklist created
- `checklist_edited` - Checklist name updated
- `checklist_deleted` - Checklist deleted
- `checklist_item_added` - Item created
- `checklist_item_toggled` - Item checked/unchecked (with `is_checked` parameter)
- `checklist_item_edited` - Item name updated
- `checklist_item_deleted` - Item deleted

### Phase 7: Cascade Delete

#### 7.1 Update Delete Logic
- When a Checklist is deleted, all its ChecklistItems must be deleted
- When a Journey is deleted, all its Checklists (and their items) must be deleted
- Update `JourneysRepository.delete()` or add cascade logic in ChecklistsRepository

### Phase 8: Testing

#### 8.1 Repository Tests
- **File:** `JourneyWalletTests/ChecklistsRepositoryTests.swift`
  - Test CRUD operations for Checklist
  - Test cascade delete when journey is deleted
- **File:** `JourneyWalletTests/ChecklistItemsRepositoryTests.swift`
  - Test CRUD operations for ChecklistItem
  - Test cascade delete when checklist is deleted
  - Test count methods
  - Test toggle functionality

#### 8.2 ViewModel Tests
- **File:** `JourneyWalletTests/ChecklistsListViewModelTests.swift`
  - Test loading checklists
  - Test progress calculations
- **File:** `JourneyWalletTests/ChecklistDetailViewModelTests.swift`
  - Test filtering logic
  - Test item toggle
  - Test progress calculations

### Phase 9: Random Data Generation

#### 9.1 Update RandomDataService
- **File:** `BusinessLogic/Services/RandomDataService.swift` (MODIFY)
- Add method: `generateChecklists(for journeyId: UUID) -> [Checklist]`
- Add method: `generateChecklistItems(for checklistId: UUID) -> [ChecklistItem]`
- Requirements:
  - Generate **3 checklists** per journey with predefined names:
    - "Packing" (items: clothes, toiletries, electronics, documents, etc.)
    - "Before Departure" (items: lock doors, turn off appliances, etc.)
    - "Documents" (items: passport, tickets, insurance, etc.)
  - Each checklist contains **5-8 items** (random count)
  - **40% of items** should have `isChecked = true`
  - Items should have sequential `sortingOrder` values (0, 1, 2, ...)
  - Checklists should have sequential `sortingOrder` values (0, 1, 2)
- Update existing journey generation to include checklists

#### 9.2 Sample Checklist Item Names
```swift
// Packing checklist
["Clothes", "Toiletries", "Phone charger", "Laptop", "Headphones",
 "Travel adapter", "Medications", "Snacks", "Book", "Sunglasses"]

// Before Departure checklist
["Lock all doors", "Turn off appliances", "Set thermostat",
 "Water plants", "Take out trash", "Notify neighbors",
 "Check windows", "Unplug electronics"]

// Documents checklist
["Passport", "Flight tickets", "Hotel confirmation", "Travel insurance",
 "Driver's license", "Credit cards", "Emergency contacts", "Itinerary"]
```

## File Structure

```
BusinessLogic/
├── Models/
│   ├── Checklist.swift                      # NEW
│   └── ChecklistItem.swift                  # NEW
├── Database/
│   ├── Migrations/
│   │   └── Migration_20260124_Checklists.swift    # NEW
│   ├── Repositories/
│   │   ├── ChecklistsRepository.swift       # NEW
│   │   └── ChecklistItemsRepository.swift   # NEW
│   └── DatabaseManager.swift                # MODIFY
├── Services/
│   └── RandomDataService.swift              # MODIFY

JourneyWallet/
├── Checklist/                               # NEW FOLDER
│   ├── ChecklistsListView.swift             # List of checklists
│   ├── ChecklistsListViewModel.swift
│   ├── ChecklistRow.swift
│   ├── ChecklistFormView.swift              # Add/Edit checklist
│   ├── ChecklistDetailView.swift            # Single checklist with items
│   ├── ChecklistDetailViewModel.swift
│   ├── ChecklistItemRow.swift
│   ├── ChecklistItemFormView.swift          # Add/Edit item
│   └── ChecklistItemFilter.swift
├── JourneyDetail/
│   ├── JourneyDetailView.swift              # MODIFY
│   └── JourneyDetailViewModel.swift         # MODIFY

JourneyWallet/
├── en.lproj/Localizable.strings             # MODIFY
├── ru.lproj/Localizable.strings             # MODIFY
├── kk.lproj/Localizable.strings             # MODIFY
├── tr.lproj/Localizable.strings             # MODIFY
├── de.lproj/Localizable.strings             # MODIFY
└── uk.lproj/Localizable.strings             # MODIFY

JourneyWalletTests/
├── ChecklistsRepositoryTests.swift          # NEW
├── ChecklistItemsRepositoryTests.swift      # NEW
├── ChecklistsListViewModelTests.swift       # NEW
└── ChecklistDetailViewModelTests.swift      # NEW
```

## Implementation Order

1. **Phase 1** - Database Layer (foundation)
   - 1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6

2. **Phase 2** - Checklists List UI
   - 2.1 → 2.3 → 2.4 → 2.2

3. **Phase 3** - Checklist Detail UI
   - 3.1 → 3.2 → 3.4 → 3.5 → 3.3

4. **Phase 4** - Integration with Journey Detail
   - 4.1 → 4.2

5. **Phase 5** - Localization

6. **Phase 6** - Analytics

7. **Phase 7** - Cascade Delete

8. **Phase 8** - Testing

9. **Phase 9** - Random Data Generation
   - 9.1 → 9.2

## UI Mockup (Text Description)

### Checklists Section on Journey Detail
```
┌─────────────────────────────────────────┐
│ ☑️ Checklists                  12/25  > │
├─────────────────────────────────────────┤
│ 📋 Packing                    ████░ 8/10│
│ 📋 Documents                  ██░░░ 2/8 │
│ 📋 Before departure           ██░░░ 2/7 │
│                                         │
│           See All (3 checklists)        │
└─────────────────────────────────────────┘
```

### Checklists List View
```
┌─────────────────────────────────────────┐
│ < Checklists                        [+] │
├─────────────────────────────────────────┤
│ 📋 Packing                              │
│    ████████░░  8/10 completed       >   │
├─────────────────────────────────────────┤
│ 📋 Documents                            │
│    ████░░░░░░  2/8 completed        >   │
├─────────────────────────────────────────┤
│ 📋 Before departure                     │
│    ███░░░░░░░  2/7 completed        >   │
└─────────────────────────────────────────┘
```

### Checklist Detail View (Items)
```
┌─────────────────────────────────────────┐
│ < Packing                     [⋯]   [+] │
├─────────────────────────────────────────┤
│ [All] [Pending] [Completed]             │
├─────────────────────────────────────────┤
│ ████████░░░░░░░░  8/10 completed (80%)  │
├─────────────────────────────────────────┤
│ ✓ Passport                    ← swipe   │
│ ✓ Clothes                               │
│ ✓ Toiletries                            │
│ ✓ Phone charger                         │
│ ✓ Laptop                                │
│ ✓ Headphones                            │
│ ✓ Travel adapter                        │
│ ✓ Medications                           │
│ ○ Snacks                                │
│ ○ Book                                  │
└─────────────────────────────────────────┘
```

## Navigation Flow

```
Journey Detail
    │
    └── Checklists Section (tap "See All")
            │
            └── ChecklistsListView (list of checklists)
                    │
                    ├── [+] → ChecklistFormView (create new checklist)
                    │
                    └── (tap checklist row)
                            │
                            └── ChecklistDetailView (items in checklist)
                                    │
                                    ├── [+] → ChecklistItemFormView (add item)
                                    │
                                    └── (swipe item) → Edit/Delete
```

## Notes

- Follow existing MVVM patterns from Hotel/Transport implementations
- Use `@Observable` for ViewModels (not `ObservableObject`)
- All strings must use `L()` function for localization
- Repository access via `DatabaseManager.shared`
- Analytics tracking for all user actions
- Ensure cascade deletes work correctly at all levels
- **Sorting:** New items get `sortingOrder = max(existing) + 1`. Reordering updates all affected items' sortingOrder values and persists to database immediately.
- **Reordering UX:** Uses iOS 16+ `.draggable()` and `.dropDestination()` modifiers. Users long-press to initiate drag, then drop to reorder. No Edit mode button required for a cleaner, more intuitive experience.
