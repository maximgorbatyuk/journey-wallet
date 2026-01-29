# Checklists Feature

## Overview

The Checklists feature allows users to create and manage multiple task lists within each journey. Perfect for organizing packing lists, pre-departure tasks, document checklists, and any other to-do items related to travel planning.

## Key Features

### Multiple Checklists per Journey
- Create unlimited checklists for each journey
- Name checklists based on purpose (e.g., "Packing", "Documents", "Before Departure")
- Reorder checklists via drag-and-drop
- Edit or delete checklists with swipe actions

### Checklist Items
- Add unlimited items to each checklist
- Tap to mark items as complete/incomplete
- Completed items show strikethrough styling
- Reorder items via drag-and-drop
- Edit or delete items with swipe actions
- "Move completed to end" action to organize checked items at the bottom

### Progress Tracking
- Visual progress bar on each checklist showing completion percentage
- Progress counter (e.g., "8/10 completed")
- Aggregate progress shown on Journey Detail page
- Last modified timestamp on checklist rows ("Today", "Yesterday", "N days ago")
- Last modified timestamp on checked items

### Filtering
- Filter items by status: All, Pending, or Completed
- Quick access to see what's left to do

### Quick Access
- Checklists section displayed as first section on Journey Detail page
- Preview of first 3 checklists with progress
- "See All" link to view all checklists
- Add checklists from "Add to journey" quick menu (teal icon)
- Floating teal add button for quick item creation

## User Interface

### Journey Detail Page
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

### Checklists List
```
┌─────────────────────────────────────────┐
│ < Checklists                        [+] │
├─────────────────────────────────────────┤
│ 📋 Packing                              │
│    ████████░░  8/10 completed           │
│    2 days ago (2026-01-22)          >   │
├─────────────────────────────────────────┤
│ 📋 Documents                            │
│    ████░░░░░░  2/8 completed            │
│    Today (2026-01-24)               >   │
└─────────────────────────────────────────┘
```

### Checklist Detail (Items)
```
┌─────────────────────────────────────────┐
│ < Packing                         [⋯]   │
├─────────────────────────────────────────┤
│ [All] [Pending] [Completed]             │
├─────────────────────────────────────────┤
│ ████████░░░░░░░░  8/10 completed (80%)  │
├─────────────────────────────────────────┤
│ ✓ Passport                              │
│   Yesterday (2026-01-23)                │
│ ✓ Clothes                               │
│   2 days ago (2026-01-22)               │
│ ○ Snacks                                │
│ ○ Book                                  │
├─────────────────────────────────────────┤
│                              [+ Button] │
└─────────────────────────────────────────┘
```

## Navigation Flow

```
Journey Detail
    │
    ├── "Add to journey" → Checklist option
    │
    └── Checklists Section
            │
            └── "See All" or tap section
                    │
                    └── Checklists List
                            │
                            ├── [+] → New Checklist form
                            │
                            └── Tap checklist
                                    │
                                    └── Checklist Detail (Items)
                                            │
                                            ├── [+] Floating button → Add Item
                                            ├── Tap item → Toggle check
                                            ├── Swipe item → Edit/Delete
                                            └── [⋯] Menu → Edit name / Move completed
```

## Use Cases

### Packing Checklist
Track items to pack: clothes, toiletries, electronics, medications, travel documents, etc.

### Documents Checklist
Ensure all travel documents are ready: passport, visas, tickets, hotel confirmations, insurance, etc.

### Before Departure Checklist
Pre-travel tasks: lock doors, turn off appliances, water plants, set thermostat, notify neighbors, etc.

### Day Trip Checklist
Items needed for specific activities: hiking gear, beach essentials, camera equipment, etc.

## Localization

Available in all supported languages:
- English (EN)
- Russian (RU)
- German (DE)
- Ukrainian (UK)
- Turkish (TR)
- Kazakh (KK)

## Technical Details

### Data Model

**Checklist:**
- `id` - Unique identifier (UUID)
- `journeyId` - Parent journey reference
- `name` - Checklist name
- `sortingOrder` - Custom sort position
- `createdAt` / `updatedAt` - Timestamps

**ChecklistItem:**
- `id` - Unique identifier (UUID)
- `checklistId` - Parent checklist reference
- `name` - Item text
- `isChecked` - Completion status
- `sortingOrder` - Custom sort position
- `createdAt` / `updatedAt` - Timestamps

### Database
- Schema version: 7
- Tables: `checklists`, `checklist_items`
- Indices on foreign keys for efficient queries
- Cascade delete: Items deleted with checklist, checklists deleted with journey

### File Structure

```
BusinessLogic/
├── Models/
│   ├── Checklist.swift
│   └── ChecklistItem.swift
├── Database/
│   ├── Migrations/
│   │   └── Migration_20260124_Checklists.swift
│   └── Repositories/
│       ├── ChecklistsRepository.swift
│       └── ChecklistItemsRepository.swift

JourneyWallet/
├── Checklist/
│   ├── ChecklistsListView.swift
│   ├── ChecklistsListViewModel.swift
│   ├── ChecklistRow.swift
│   ├── ChecklistFormView.swift
│   ├── ChecklistDetailView.swift
│   ├── ChecklistDetailViewModel.swift
│   ├── ChecklistItemRow.swift
│   ├── ChecklistItemFormView.swift
│   └── ChecklistItemFilter.swift
└── JourneyDetail/
    ├── QuickAddEntityType.swift (checklist case)
    └── QuickAddSheet.swift (checklist handling)
```

### Architecture
- MVVM pattern with `@Observable` ViewModels
- Sheet-based navigation (consistent with Transport, Hotel, Car Rental views)
- Drag-and-drop reordering using iOS 16+ `.draggable()` and `.dropDestination()` modifiers
- All strings localized using `L()` function
