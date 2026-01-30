# JWF-3: Add "Idea" Entity to Journey Wallet

## Overview

Add a new entity called "Idea" that allows users to save travel inspiration, tips, and content ideas associated with their journeys. Ideas can contain links to videos, Instagram posts, blog articles, or any other travel inspiration content.

## Requirements

Based on the roadmap specification:
- **Title**: Required field
- **Description**: Optional field for additional details
- **URL**: Optional field for video, Instagram post, blog article, etc.
- **Journey attachment**: Each Idea belongs to a Journey
- **Done status**: Mark ideas as done (swipe right gesture)
- **Timestamps**: Track creation and last update time
- **Move to Journey**: Ability to move idea to another journey
- **Share**: Share idea content via system share sheet

## Comparison with PlaceToVisit

| Aspect | PlaceToVisit | Idea |
|--------|--------------|------|
| Required fields | name | title |
| Optional text | address, notes | description |
| URL | url (optional) | url (optional) |
| Status tracking | isVisited, plannedDate | isDone (simpler) |
| Timestamps | createdAt | createdAt, updatedAt |
| Category | PlaceCategory enum (7 types) | None (could add later) |
| Move to Journey | Yes | Yes |
| Share | No | Yes |
| Complexity | Higher (filters, progress) | Medium |

**Reuse Opportunities:**
1. URL display component (link button + copy button) - same pattern
2. Form validation pattern (required field check)
3. Detail view card components
4. Preview row pattern for dashboard
5. Move to journey functionality (MoveToJourneySheet)
6. Swipe gesture for status toggle (same as PlaceToVisit)

---

## Data Model

### Idea.swift

```swift
struct Idea: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var title: String           // Required
    var description: String?    // Optional
    var url: String?            // Optional - video, Instagram, etc.
    var isDone: Bool            // Completion status
    let createdAt: Date
    var updatedAt: Date         // Last modification timestamp

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        title: String,
        description: String? = nil,
        url: String? = nil,
        isDone: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.title = title
        self.description = description
        self.url = url
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Generates shareable text for the idea
    var shareText: String {
        var text = "Hey! I found a great idea: \(title)"
        if let description = description, !description.isEmpty {
            text += "\n\(description)"
        }
        if let url = url, !url.isEmpty {
            text += "\n\(url)"
        }
        return text
    }
}
```

---

## Database Schema

### Migration

New migration: `Migration_YYYYMMDD_IdeasTable.swift`

```sql
CREATE TABLE ideas (
    id VARCHAR PRIMARY KEY NOT NULL,
    journey_id VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    description VARCHAR,
    url VARCHAR,
    is_done BOOLEAN NOT NULL DEFAULT 0,
    created_at DATE NOT NULL,
    updated_at DATE NOT NULL
);

CREATE INDEX idx_ideas_journey_id ON ideas(journey_id);
```

### Repository Methods

**IdeasRepository.swift:**

| Method | Purpose |
|--------|---------|
| `fetchAll()` | Fetch all ideas, ordered by isDone asc, then updatedAt desc |
| `fetchByJourneyId(journeyId: UUID)` | Fetch ideas for a journey |
| `fetchById(id: UUID)` | Fetch single idea |
| `fetchPending(journeyId: UUID)` | Fetch not-done ideas for a journey |
| `fetchDone(journeyId: UUID)` | Fetch done ideas for a journey |
| `insert(_ idea: Idea)` | Create new idea |
| `update(_ idea: Idea)` | Update existing idea (also updates updatedAt) |
| `toggleDone(id: UUID)` | Toggle done status (also updates updatedAt) |
| `delete(id: UUID)` | Delete single idea |
| `deleteByJourneyId(journeyId: UUID)` | Delete all ideas for journey |
| `updateJourneyId(id: UUID, newJourneyId: UUID)` | Move idea to different journey |
| `count()` | Total count |
| `countByJourneyId(journeyId: UUID)` | Count for journey |
| `countDone(journeyId: UUID)` | Count done ideas for journey |

---

## UI Mockups

### 1. Journey Detail Dashboard (Ideas Section)

```
┌─────────────────────────────────────────┐
│  💡 Ideas                  1/3  See All │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 💡  Best viewpoints in Paris       │ │
│ │     🔗 youtube.com                 │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ✓  Hidden gems from @traveler  ✓   │ │
│ │     🔗 instagram.com      (done)   │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 💡  Local food recommendations     │ │
│ │     (no URL)                       │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘

Note: Shows "X/Y" progress (done/total)
```

### 2. Ideas List View

```
┌─────────────────────────────────────────┐
│ ←  Ideas                            ＋  │
├─────────────────────────────────────────┤
│  1/3 done                               │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 💡  Best viewpoints in Paris     │  │
│  │     Great spots for photography   │  │
│  │     🔗 youtube.com          📋 🔗 │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 💡  Local food recommendations   │  │
│  │     Try the street food near...   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ── Done ─────────────────────────────  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ ✓  Hidden gems from @traveler    │  │
│  │     ~~Must visit these spots~~    │  │
│  │     🔗 instagram.com        📋 🔗 │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ← Swipe LEFT: Edit/Delete              │
│  → Swipe RIGHT: Mark Done/Undone        │
│                                         │
└─────────────────────────────────────────┘
```

### 3. Idea Detail View

```
┌─────────────────────────────────────────┐
│ ←  Idea                    ⋮ (Menu)     │
├─────────────────────────────────────────┤
│                                         │
│            💡                           │
│   Best viewpoints in Paris              │
│        ┌────────────┐                   │
│        │ Not Done   │  (or "Done" green)│
│        └────────────┘                   │
│                                         │
├─────────────────────────────────────────┤
│  DESCRIPTION                            │
│ ┌───────────────────────────────────┐   │
│ │ Great spots for photography and   │   │
│ │ sunset watching. Don't miss the   │   │
│ │ view from Montmartre!             │   │
│ └───────────────────────────────────┘   │
│                                         │
│  LINK                                   │
│ ┌───────────────────────────────────┐   │
│ │ 🔗  youtube.com                   │   │
│ │                                   │   │
│ │  ┌──────────┐  ┌──────────────┐   │   │
│ │  │  📋 Copy │  │  🔗 Open URL │   │   │
│ │  └──────────┘  └──────────────┘   │   │
│ └───────────────────────────────────┘   │
│                                         │
│  ACTIONS                                │
│ ┌───────────────────────────────────┐   │
│ │  ┌─────────────────────────────┐  │   │
│ │  │  ✓ Mark as Done             │  │   │
│ │  └─────────────────────────────┘  │   │
│ │  ┌─────────────────────────────┐  │   │
│ │  │  📤 Share Idea              │  │   │
│ │  └─────────────────────────────┘  │   │
│ └───────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│ Created: Jan 15, 2026                   │
│ Updated: Jan 20, 2026                   │
└─────────────────────────────────────────┘

Toolbar Menu (⋮):
  - Edit
  - Mark as Done / Mark as Not Done
  - Move to Journey
  - Share
  - Delete
```

### 3a. Share Sheet Content

When user taps "Share", the following text is copied/shared:

```
Hey! I found a great idea: Best viewpoints in Paris
Great spots for photography and sunset watching.
https://youtube.com/watch?v=xyz
```

Format: `Hey! I found a great idea: <Title>\n<Description if available>\n<URL if available>`

### 4. Idea Form (Add/Edit)

```
┌─────────────────────────────────────────┐
│ Cancel    New Idea              Save    │
├─────────────────────────────────────────┤
│                                         │
│  INFO                                   │
│ ┌───────────────────────────────────┐   │
│ │ Title *                           │   │
│ │ ┌─────────────────────────────┐   │   │
│ │ │ Best viewpoints in Paris   │   │   │
│ │ └─────────────────────────────┘   │   │
│ └───────────────────────────────────┘   │
│                                         │
│  DESCRIPTION                            │
│ ┌───────────────────────────────────┐   │
│ │ ┌─────────────────────────────┐   │   │
│ │ │ Great spots for photography │   │   │
│ │ │ and sunset watching...      │   │   │
│ │ │                             │   │   │
│ │ └─────────────────────────────┘   │   │
│ └───────────────────────────────────┘   │
│                                         │
│  LINK                                   │
│ ┌───────────────────────────────────┐   │
│ │ URL                               │   │
│ │ ┌─────────────────────────────┐   │   │
│ │ │ https://youtube.com/watch.. │   │   │
│ │ └─────────────────────────────┘   │   │
│ │ Video, Instagram post, article    │   │
│ └───────────────────────────────────┘   │
│                                         │
│  STATUS (edit mode only)                │
│ ┌───────────────────────────────────┐   │
│ │ Done                      [ OFF ] │   │
│ └───────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│  [ Move to Another Journey ]  (edit)    │
│                                         │
└─────────────────────────────────────────┘

Note: "Move to Another Journey" uses MoveToJourneySheet
(same component used by PlaceToVisit and other entities)
```

### 5. Quick Add Sheet (Add to Journey)

```
┌─────────────────────────────────────────┐
│ Cancel       Add to Journey             │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────┐      ┌───────────┐       │
│  │    ✈️     │      │    🏨     │       │
│  │ Transport │      │   Hotel   │       │
│  └───────────┘      └───────────┘       │
│                                         │
│  ┌───────────┐      ┌───────────┐       │
│  │    🚗     │      │    ✓      │       │
│  │Car Rental │      │ Checklist │       │
│  └───────────┘      └───────────┘       │
│                                         │
│  ┌───────────┐      ┌───────────┐       │
│  │    📄     │      │    📝     │       │
│  │ Document  │      │   Note    │       │
│  └───────────┘      └───────────┘       │
│                                         │
│  ┌───────────┐      ┌───────────┐       │
│  │    📍     │      │    🔔     │       │
│  │   Place   │      │ Reminder  │       │
│  └───────────┘      └───────────┘       │
│                                         │
│  ┌───────────┐      ┌───────────┐       │
│  │    💰     │      │    💡     │       │
│  │  Expense  │      │   Idea    │  ← NEW│
│  └───────────┘      └───────────┘       │
│                                         │
└─────────────────────────────────────────┘

Idea button: lightbulb.fill icon, yellow color
```

### 6. Empty State

```
┌─────────────────────────────────────────┐
│ ←  Ideas                            ＋  │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│               💡                        │
│                                         │
│        No ideas yet                     │
│                                         │
│   Save travel inspiration, tips,        │
│   videos, and content for your trip     │
│                                         │
│        ┌─────────────────┐              │
│        │   Add Idea      │              │
│        └─────────────────┘              │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Data Layer

1. **Create Idea Model**
   - File: `BusinessLogic/Models/Idea.swift`
   - Struct with 8 fields (id, journeyId, title, description, url, isDone, createdAt, updatedAt)
   - Add `shareText` computed property for Share feature

2. **Create Database Migration**
   - File: `BusinessLogic/Database/Migrations/Migration_YYYYMMDD_IdeasTable.swift`
   - Create `ideas` table with index on journey_id
   - Include is_done, created_at, updated_at columns

3. **Create IdeasRepository**
   - File: `BusinessLogic/Database/Repositories/IdeasRepository.swift`
   - ~14 methods following PlacesToVisitRepository pattern
   - Include toggleDone, fetchPending, fetchDone, countDone methods
   - All update operations must set updatedAt to current timestamp

4. **Register in DatabaseManager**
   - Add `ideasRepository` property
   - Initialize in `initializeDatabase()`
   - Add to `deleteAllData()`

### Phase 2: View Layer

5. **Create IdeaFormView**
   - File: `JourneyWallet/Idea/IdeaFormView.swift`
   - Reuse form patterns from PlaceFormView
   - Fields: title (required), description, url
   - Edit mode: isDone toggle, "Move to Another Journey" button
   - Use MoveToJourneySheet component (already exists)

6. **Create IdeaDetailViewModel**
   - File: `JourneyWallet/Idea/IdeaDetailViewModel.swift`
   - Methods: updateIdea, deleteIdea, toggleDone, moveToJourney, shareIdea

7. **Create IdeaDetailView**
   - File: `JourneyWallet/Idea/IdeaDetailView.swift`
   - Reuse card component patterns
   - Reuse URL display/copy/open pattern
   - Show status badge (Done/Not Done)
   - Show createdAt and updatedAt timestamps
   - Actions section: Mark as Done, Share Idea buttons
   - Toolbar menu: Edit, Mark Done/Undone, Move to Journey, Share, Delete
   - Share uses iOS ShareLink with `idea.shareText`

8. **Create IdeaListViewModel**
   - File: `JourneyWallet/Idea/IdeaListViewModel.swift`
   - State: ideas, doneCount, totalCount, progressPercentage
   - Methods: loadData, addIdea, updateIdea, deleteIdea, toggleDone, moveToJourney
   - Sorting: not-done first (by updatedAt desc), then done (by updatedAt desc)

9. **Create IdeaListView**
   - File: `JourneyWallet/Idea/IdeaListView.swift`
   - Progress summary bar ("X/Y done")
   - List grouped by status (pending items, then "Done" section)
   - Swipe actions:
     - Left (trailing): Edit, Delete
     - Right (leading): Mark Done/Undone (full swipe)
   - Done items show strikethrough on title

10. **Create IdeaPreviewRow**
    - Add to `JourneyWallet/JourneyDetail/SectionPreviewViews.swift`
    - Mini card: icon (💡 or ✓), title, URL domain, done status indicator

### Phase 3: Integration

11. **Update JourneyDetailView**
    - Add Ideas section after Places section
    - Show icon, progress "X/Y", "See All" navigation
    - Display up to 3 recent ideas (pending first)

12. **Update JourneyDetailViewModel**
    - Load ideas count (total and done)
    - Load recent ideas for preview

13. **Add Idea to Quick Add Sheet**
    - Add `idea` case to `QuickAddEntityType` enum
      - displayName: `L("quick_add.idea")`
      - iconName: `"lightbulb.fill"`
      - iconColor: `.yellow`
    - Add case in `QuickAddSheet.formView(for:)` to show `IdeaFormView`

14. **Add Localization Keys**
    - Add keys to all 6 language files
    - Keys: idea.list.*, idea.form.*, idea.detail.*, idea.action.*, idea.share.*, quick_add.idea

15. **Add Analytics Events**
    - idea_list_screen, idea_created, idea_updated, idea_deleted
    - idea_marked_done, idea_shared, idea_moved
    - add_idea_button_clicked

### Phase 4: Testing & Polish

16. **Test all flows**
    - Create, read, update, delete
    - Toggle done status (swipe right + button + menu)
    - Move between journeys (MoveToJourneySheet)
    - Share idea (verify text format)
    - URL opening and copying
    - Quick Add sheet → Idea
    - Empty states

17. **Run linting and formatting**
    - `./scripts/run_all_checks.sh`

---

## Reusable Components Analysis

### Can Potentially Extract to Shared Components:

1. **URLDisplayView** - Display URL with domain, copy and open buttons
   - Currently duplicated in PlaceListView, PlaceDetailView
   - Could be: `Components/URLDisplayView.swift`

2. **CardSection** - Consistent card styling used in detail views
   - Could be: `Components/DetailCardSection.swift`

3. **EmptyStateView** - Empty state with icon, title, subtitle, button
   - Currently inline in multiple views
   - Could be: `Components/EmptyStateView.swift`

### For This Implementation:
Given the scope, I recommend **keeping components inline** for now and extracting shared components in a future refactoring task. This keeps the PR focused and reduces risk.

---

## Files to Create/Modify

### New Files (9 files):

| File | Type |
|------|------|
| `BusinessLogic/Models/Idea.swift` | Model |
| `BusinessLogic/Database/Migrations/Migration_YYYYMMDD_IdeasTable.swift` | Migration |
| `BusinessLogic/Database/Repositories/IdeasRepository.swift` | Repository |
| `JourneyWallet/Idea/IdeaFormView.swift` | View |
| `JourneyWallet/Idea/IdeaListView.swift` | View |
| `JourneyWallet/Idea/IdeaListViewModel.swift` | ViewModel |
| `JourneyWallet/Idea/IdeaDetailView.swift` | View |
| `JourneyWallet/Idea/IdeaDetailViewModel.swift` | ViewModel |
| `JourneyWallet/Idea/` | Directory |

### Files to Modify (12 files):

| File | Changes |
|------|---------|
| `BusinessLogic/Database/DatabaseManager.swift` | Add ideasRepository property and initialization |
| `JourneyWallet/JourneyDetail/JourneyDetailView.swift` | Add Ideas section to dashboard |
| `JourneyWallet/JourneyDetail/JourneyDetailViewModel.swift` | Load ideas data |
| `JourneyWallet/JourneyDetail/SectionPreviewViews.swift` | Add IdeaPreviewRow |
| `JourneyWallet/JourneyDetail/QuickAddEntityType.swift` | Add `idea` case with icon and color |
| `JourneyWallet/JourneyDetail/QuickAddSheet.swift` | Add case for IdeaFormView |
| `JourneyWallet/en.lproj/Localizable.strings` | Add idea.* and quick_add.idea keys |
| `JourneyWallet/ru.lproj/Localizable.strings` | Add idea.* and quick_add.idea keys |
| `JourneyWallet/de.lproj/Localizable.strings` | Add idea.* and quick_add.idea keys |
| `JourneyWallet/tr.lproj/Localizable.strings` | Add idea.* and quick_add.idea keys |
| `JourneyWallet/kk.lproj/Localizable.strings` | Add idea.* and quick_add.idea keys |
| `JourneyWallet/uk.lproj/Localizable.strings` | Add idea.* and quick_add.idea keys |

---

## Localization Keys

```
// List
"idea.list.title" = "Ideas";
"idea.list.empty.title" = "No ideas yet";
"idea.list.empty.subtitle" = "Save travel inspiration, tips, videos, and content for your trip";
"idea.list.empty.button" = "Add Idea";
"idea.list.section.done" = "Done";
"idea.list.progress" = "%d/%d done";

// Form
"idea.form.title.new" = "New Idea";
"idea.form.title.edit" = "Edit Idea";
"idea.form.field.title" = "Title";
"idea.form.field.title.required" = "Title is required";
"idea.form.field.description" = "Description";
"idea.form.field.url" = "URL";
"idea.form.field.url.hint" = "Video, Instagram post, article";
"idea.form.field.done" = "Done";
"idea.form.section.info" = "Info";
"idea.form.section.description" = "Description";
"idea.form.section.link" = "Link";
"idea.form.section.status" = "Status";
"idea.form.move_to_journey" = "Move to Another Journey";

// Detail
"idea.detail.title" = "Idea";
"idea.detail.section.description" = "Description";
"idea.detail.section.link" = "Link";
"idea.detail.section.actions" = "Actions";
"idea.detail.created" = "Created";
"idea.detail.updated" = "Updated";
"idea.detail.status.done" = "Done";
"idea.detail.status.not_done" = "Not Done";

// Actions
"idea.action.edit" = "Edit";
"idea.action.delete" = "Delete";
"idea.action.move" = "Move to Journey";
"idea.action.share" = "Share Idea";
"idea.action.mark_done" = "Mark as Done";
"idea.action.mark_not_done" = "Mark as Not Done";
"idea.action.open_url" = "Open URL";
"idea.action.copy_url" = "Copy URL";

// Delete confirmation
"idea.delete.confirm.title" = "Delete Idea";
"idea.delete.confirm.message" = "Are you sure you want to delete this idea?";

// Share
"idea.share.prefix" = "Hey! I found a great idea:";

// Dashboard section
"journey.detail.section.ideas" = "Ideas";

// Quick Add sheet
"quick_add.idea" = "Idea";
```

---

## Estimated Effort

| Phase | Tasks |
|-------|-------|
| Phase 1: Data Layer | 4 tasks |
| Phase 2: View Layer | 6 tasks |
| Phase 3: Integration | 5 tasks |
| Phase 4: Testing | 2 tasks |
| **Total** | **17 tasks** |

---

## Open Questions

1. **Icon for Ideas**: Should we use `lightbulb.fill` (💡) or another SF Symbol?
   - Recommendation: `lightbulb.fill` with yellow/gold color

2. **Sorting**: How should ideas be sorted?
   - Recommendation: Not-done first (by updatedAt desc), then done (by updatedAt desc)
   - This keeps active ideas at top, recently updated first

3. **Done icon**: What icon for done ideas?
   - Recommendation: `checkmark.circle.fill` (green) when done, `lightbulb.fill` (yellow) when not done

4. **Future: Categories?**: Should we add categories to Ideas later (like PlaceToVisit)?
   - Recommendation: Start simple, add categories if users request it

---

## Acceptance Criteria

### Core CRUD
- [ ] User can view Ideas section in Journey dashboard (with X/Y progress)
- [ ] User can see full list of Ideas for a Journey
- [ ] User can add a new Idea with title (required), description, and URL (optional)
- [ ] User can add a new Idea from Quick Add sheet ("Add to Journey")
- [ ] User can edit an existing Idea
- [ ] User can delete an Idea (with confirmation)
- [ ] User can view Idea details with URL copy/open functionality

### Done Status
- [ ] User can mark Idea as done via swipe right gesture (full swipe)
- [ ] User can mark Idea as done via button in detail view
- [ ] User can mark Idea as done via toolbar menu
- [ ] Done ideas show strikethrough on title in list
- [ ] Done ideas are grouped separately in list (under "Done" section)
- [ ] Progress is shown as "X/Y done" in list and dashboard

### Timestamps
- [ ] createdAt is set when Idea is created
- [ ] updatedAt is set when Idea is created
- [ ] updatedAt is updated on any modification (edit, toggle done, move)
- [ ] Both timestamps are displayed in detail view

### Move to Journey
- [ ] User can move Idea to another Journey via form (edit mode)
- [ ] User can move Idea to another Journey via toolbar menu
- [ ] MoveToJourneySheet component is reused

### Share
- [ ] User can share Idea via button in detail view
- [ ] User can share Idea via toolbar menu
- [ ] Share text format: "Hey! I found a great idea: <Title>\n<Description>\n<URL>"
- [ ] Description and URL are only included if present

### Polish
- [ ] Empty states display correctly
- [ ] All UI text is localized in 6 languages
- [ ] Analytics events are tracked
- [ ] Code passes linting and formatting checks
