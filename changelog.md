# Changelog

# 2026.1.6 (2026-03-21)

## Improvements

### Document Viewer
- Extracted `CameraView` into a shared reusable component at `JourneyWallet/Shared/CameraView.swift`, removed inline implementation from `DocumentPickerView`
- Added `source` field to `PendingDocument` to track document origin (`camera`, `photo_library`, `files`)
- Added analytics event `document_added` with `screen` and `source` properties when a document is successfully saved
- Migrated `DocumentPickerView`, `DocumentNameEntryView`, and `DocumentPreviewView` from deprecated `NavigationView` to `NavigationStack`
- Replaced `print()` calls with `GlobalLogger.shared.error()` for proper error logging

### Camera Permission Localization
- Added `NSCameraUsageDescription` to `Info.plist` with base English string
- Added localized camera permission descriptions in all 6 supported languages (EN, DE, RU, TR, KK, UK) via `InfoPlist.strings`

### Error Alert Bindings
- Fixed `.alert` bindings in `ErrorStateView`, `UserSettingsView`, and `iCloudBackupListView` — replaced `.constant(error != nil)` with proper computed `Binding<Bool>` that correctly dismisses alerts on user interaction

### Website
- Redesigned landing page footer with a 3-column grid layout (brand column, app links, resources)
- Added responsive CSS for mobile breakpoints, hover states, and brutalism card styling for the footer

## Internal

- Version bumped from 2026.1.5 to 2026.1.6 across all targets (app and share extension, Debug and Release)
- Updated `CLAUDE.md` directory structure documentation

---

# 2026.1.5 (2026-02-07)

## New Features

### Roadmap Timeline
- Added a new **Roadmap** tab replacing the Reminders tab in the main tab bar, providing a visual trip timeline
- New `RoadmapStop` model with title, subtitle, arrival/departure dates, notes, and sort order
- New `RoadmapStopAttachment` model to link existing journey entities (hotels, car rentals, transport, places, ideas) to timeline stops
- Full timeline UI: `RoadmapTimelineView`, `RoadmapStopRow`, `RoadmapStopDetailView`, `RoadmapStopFormView`, and `RoadmapConnectionView`
- `RoadmapAttachmentPicker` for attaching journey items to stops
- `RoadmapAttachmentBanner` displayed on detail views (hotels, car rentals, transport, places, ideas) showing which timeline stop an entity is attached to, with a detach action
- Transport connection support between stops with visual connectors
- Date inconsistency warnings when stop dates overlap with the next stop
- "Reset Timeline" option to clear all stops without affecting other journey data
- Drag-to-reorder support for stops
- Database migration v9: `roadmap_stops` and `roadmap_stop_attachments` tables
- New repositories: `RoadmapStopsRepository` and `RoadmapStopAttachmentsRepository`

### Launch Screen
- Added animated launch screen showing the app icon, app name, version, and developer name
- Smooth fade transition from launch screen into the main content

### Reminders Stat Card
- Replaced the "Upcoming Trips" stat card on the main screen with a "Reminders" card showing incomplete reminder count
- Reminders card navigates directly to the Notifications view on tap

## Improvements

### Journey "Last Updated" Tracking
- Added `touchUpdatedAt()` to `JourneysRepository` to update a journey's timestamp when its child entities change
- All ViewModels (budget, car rentals, checklists, documents, hotels, ideas, notes, places, transport) now update the parent journey's `updatedAt` on create, update, delete, and move operations
- Journeys list now sorts by `updatedAt` (most recently modified first) instead of `startDate`
- Share Extension journey list also sorted by `updatedAt`

### Journey Stats
- Added "Created" and "Last Updated" date rows to the journey statistics view

### Onboarding
- Added two new onboarding pages: "Packing Checklists" and "Build Your Roadmap"

### Navigation
- Migrated `MainView` from deprecated `NavigationView` to `NavigationStack`

### Backup & Export
- Roadmap stops and stop attachments are now included in data export and import

### Random Data Generator
- Generates 5-10 roadmap stops per journey with randomized dates, notes, and names
- Attaches hotels, car rentals, places, and ideas to stops
- Creates 2-3 transport connections between stops

### Localization
- Added 46 new localization keys for the roadmap feature across all 6 supported languages (EN, RU, DE, UK, TR, KK)
- Added `app.name`, `open.details`, `main.stats.reminders`, `journey.stats.created_at`, `journey.stats.updated_at` keys
- Added onboarding keys for checklists and roadmap pages

---

# 2026.1.4 (2026-01-30)

## New Features

### Ideas
- Added new Ideas entity to capture travel inspirations and notes
- Support for ideas with title, description, and optional URL
- Mark ideas as done when you've acted on them
- Share ideas with formatted text
- Quick add to journeys from share extension

### Share Functionality
- Added share buttons to all detail views:
  - Transport - Share all transport details (route, times, carrier, booking reference)
  - Hotel - Share hotel booking information
  - Car Rental - Share rental details
  - Place - Share location information
  - Idea - Share your travel ideas
- Tap-to-copy functionality for key details:
  - Transport: Booking reference, platform number, seat number
  - Hotel: Phone number
  - Car Rental: Booking reference

### Developer Tools
- Document Storage Browser - View all files in app's document storage
- Browse journey folders and files independently of database
- View file details (size, type, dates)
- Quick Look preview for files
- Delete files with confirmation
- Storage usage statistics

## UI Improvements

### Compact Action Buttons
- Replaced large action buttons with compact button bar
- Consistent UI across Transport, Hotel, CarRental, and Idea detail views
- Better visual hierarchy with icon-only buttons
- More screen space for content

## Bug Fixes
- Fixed ShareSheet parameter naming (activityItems → items)
- Various UI consistency improvements

## Localization
- Added 119 new localization strings for Ideas feature
- Added 22 new localization strings for Document Storage Browser
- Added 8 new localization strings for Transport share functionality
- Full localization support in all 6 languages (English, Russian, German, Turkish, Kazakh, Ukrainian)

## Technical Changes
- Added IdeasRepository with full CRUD operations
- Added database migration for Ideas entity
- Added DocumentStorageService for raw file system access
- Random data generator support for Ideas
- Backup/Import service updated to include Ideas

---

# 2026.1.3 (2026-01-29)

## New Features

### Place Detail View
- Added dedicated detail view for places to visit
- View all place information including name, address, URL, notes, and associated journey
- Open place location directly in Apple Maps

### Move to Journey
- Move any item to a different journey with a single tap
- Supported items: expenses, notes, places, documents, checklists, hotels, transports, and car rentals
- Easily reorganize your travel data across journeys

## Improvements

- Refactored Share Extension for better performance and maintainability
- Updated website with Share Extension screenshot
- Added documentation for upcoming features (Spotlight Search, Share Place)

## Localization

- All new features fully localized in: English, German, Russian, Turkish, Kazakh, Ukrainian

---

# 2026.1.2 (2026-01-22)

## New Features

### Share Extension
- Share files directly from other apps (Mail, Files, Safari, etc.) to Journey Wallet
- Select which journey to add the document to from the Share sheet
- Optionally set a custom display name for the document
- Supports PDFs and images (JPEG, PNG, HEIC)
- Share up to 10 files at once

### Share Text & Links
- Share text and URLs from any app (Safari, Mail, Notes, etc.)
- Choose what type of entity to create: Transport, Hotel, Car Rental, Note, or Place to Visit
- Smart content detection suggests entity type based on keywords (flight, hotel, rental, etc.)
- Automatic booking reference extraction from shared text
- Pre-fills title and notes from shared content
- Shared URLs saved to dedicated URL field for Place to Visit entities

### Place to Visit URL Field
- New URL field for storing website links, Instagram posts, booking pages, etc.
- Clickable link icon opens URL in browser when valid
- Separate from address field for better organization

### Checklists
- Create multiple checklists per journey (e.g., "Packing", "Documents", "Before Departure")
- Add unlimited items to each checklist with tap-to-check functionality
- Track progress with visual progress bars showing completion percentage
- Filter items by status: All, Pending, or Completed
- "Move completed to end" action to organize checked items at the bottom
- Last modified timestamp shown on checklist rows ("Today", "Yesterday", "N days ago")
- Last modified timestamp shown on checked items only
- Reorder checklists and items via drag-and-drop
- Floating teal "Add" button for quick item creation
- Add checklists from "Add to journey" quick menu
- Checklists section displayed first on Journey Detail page
- Full localization in all 6 languages (EN, RU, DE, UK, TR, KK)

### Color Scheme Selector
- Choose between Dark, Light, or System appearance mode
- System mode follows device settings automatically
- Preference saved to database and persists across sessions
- Available in Settings → Base Settings

### Journey Stats
- Tap on any journey in the Journeys list to view statistics
- Shows counts for: Flights, Trains, Other transports, Hotels, Car Rentals, Documents, Places, Notes
- Beautiful grid layout with colored icons
- Displays journey name, destination, and date range

## Improvements

### Journeys List
- Added floating "Add" button for quick journey creation
- Tap on journey row to view journey statistics

### Place to Visit
- Copy button for URL field with visual feedback (accent color animation)
- Copy button for Address field - easily copy to paste into Uber or taxi apps
- URL displayed in place list with copy functionality

### Transport Form
- Default departure date now set to journey start date instead of current date
- Makes it easier to add transports for future trips

### User Settings
- Added color scheme picker with icons for each mode
- Improved journey picker UI - hides empty destination text
- Developer mode: Added "View user_settings table" for debugging
- Developer mode: Added "Reset App Group Migration Flag" button with confirmation dialog

### Data Migration
- Database automatically migrates to shared App Group container on first launch
- Documents folder migrates to shared container
- Enables seamless data access between main app and Share Extension
- Migration runs once and is tracked to prevent re-running

### Localization
- Added translations for Share Extension UI in all 6 languages (EN, RU, DE, UK, TR, KK)
- Added color scheme labels in all languages
- Added entity type labels for text/link sharing (Transport, Hotel, Car Rental, Note, Place)
- Added form labels for shared content (title, booking reference, notes)
- Added Place URL field labels in all languages

## Technical

### Share Extension Architecture
- Single ShareExtension target with xcconfig-based configuration
- Dynamic bundle ID and App Group based on build configuration (Debug/Release)
- Separate entitlements files for Debug and Release builds
- Extension shares database and documents with main app via App Group

### New Files
- `ShareExtension/` - Share Extension target files
- `ShareExtension/Models/SharedContentType.swift` - Content type enum (files, text, URL)
- `ShareExtension/Models/ShareEntityType.swift` - Entity type enum with ContentAnalyzer
- `BusinessLogic/Helpers/AppGroupContainer.swift` - Shared container access helper
- `BusinessLogic/Database/DatabaseMigrationHelper.swift` - One-time migration utility
- `BusinessLogic/Database/Migrations/Migration_20260123_PlaceUrlField.swift` - Add URL field to places
- `BusinessLogic/Components/CopyButton.swift` - Reusable clipboard button with visual feedback
- `JourneyWallet/Services/ColorSchemeManager.swift` - Color scheme persistence
- `JourneyWallet/Journeys/JourneyStatsView.swift` - Journey statistics modal view
- `JourneyWallet/Journeys/JourneyStatsViewModel.swift` - Journey statistics view model
- `docs/plans/SHARE_EXTENSION_PLAN.md` - Share Extension documentation
- `docs/plans/SHARE_TEXT_EXTENSION_PLAN.md` - Text/Link sharing documentation
- `BusinessLogic/Models/Checklist.swift` - Checklist data model
- `BusinessLogic/Models/ChecklistItem.swift` - Checklist item data model
- `BusinessLogic/Database/Repositories/ChecklistsRepository.swift` - Checklist CRUD operations
- `BusinessLogic/Database/Repositories/ChecklistItemsRepository.swift` - Checklist item CRUD operations
- `BusinessLogic/Database/Migrations/Migration_20260124_Checklists.swift` - Checklist tables migration
- `JourneyWallet/Checklist/ChecklistsListView.swift` - Checklists list view
- `JourneyWallet/Checklist/ChecklistsListViewModel.swift` - Checklists list view model
- `JourneyWallet/Checklist/ChecklistRow.swift` - Checklist row component
- `JourneyWallet/Checklist/ChecklistFormView.swift` - Add/Edit checklist form
- `JourneyWallet/Checklist/ChecklistDetailView.swift` - Checklist detail with items
- `JourneyWallet/Checklist/ChecklistDetailViewModel.swift` - Checklist detail view model
- `JourneyWallet/Checklist/ChecklistItemRow.swift` - Checklist item row component
- `JourneyWallet/Checklist/ChecklistItemFormView.swift` - Add/Edit item form
- `JourneyWallet/Checklist/ChecklistItemFilter.swift` - Item filter enum
- `JourneyWallet/JourneyDetail/QuickAddEntityType.swift` - Added checklist case
- `IMPLEMENTATION_PLAN_CHECKLISTS.md` - Checklist feature implementation plan

### Database
- Migration 6: Added `url` column to `places_to_visit` table
- Migration 7: Added `checklists` and `checklist_items` tables with foreign key indices

### Configuration
- Added `APP_GROUP_IDENTIFIER` to xcconfig files
- Added `SHARE_EXTENSION_BUNDLE_ID` to xcconfig files
- Added `AppGroupIdentifier` to Info.plist
- Added App Groups entitlements to main app

---

# 2026.1.1 (2026-01-19)

## New Features

### Journey Management
- Full journey CRUD operations with name, destination, date range, and notes
- Journey selector for quick switching between trips
- Active journeys dashboard on home screen
- Journey filtering by status (upcoming, active, past)
- Journey sorting by date, name, or destination

### Transport Booking Management
- Support for multiple transport types: flights, trains, buses, ferries, transfers
- Type-specific fields and labels (terminal for flights, platform for trains)
- Departure/arrival tracking with countdown timers
- Booking reference and seat information storage
- Cost tracking with multi-currency support

### Hotel Management
- Hotel booking storage with check-in/check-out dates
- Room type and booking reference tracking
- Contact information and address storage
- Nights count calculation

### Car Rental Management
- Pickup and dropoff location tracking
- Rental duration display
- Booking reference and car type storage

### Document Storage
- PDF, JPEG, and PNG file support
- In-app document viewing with PDFKit for PDFs
- Image viewing with pinch-to-zoom
- Share Extension for importing files from other apps via system share sheet
- Document sharing to other apps

### Notes & Places
- Journey notes with title and content
- Places to visit with categories (restaurant, attraction, museum, shopping, nature)
- Visited/not visited status tracking
- Planned date support for places

### Budget & Expenses
- Expense tracking by category (transport, accommodation, food, activities, shopping)
- Multi-currency expense support
- Budget summary with category breakdown
- Visual expense breakdown

### Reminders & Notifications
- Custom reminders linked to journeys
- Transport departure reminders (24h, 3h, 1h before)
- Hotel check-in reminders
- Car rental pickup reminders
- Notifications tab showing all upcoming reminders grouped by date

### Search
- Global search across journeys, transports, hotels, car rentals, documents, notes, and places
- Search result navigation to specific entity views
- Journey context shown in search results

### Statistics
- Total journeys count
- Countries/cities visited tracking
- Spending summaries by category
- Upcoming trips overview

### Quick Add
- Floating action button for quick entity creation
- Add transport, hotel, car rental, document, note, place, reminder, or expense from journey detail view

## Improvements
- Updated tab navigation with 5 tabs: Home, Journey Details, All Journeys, Notifications, Settings
- Empty state views for all sections
- Loading skeleton views
- Consistent error handling UI
- Updated onboarding flow for journey tracking features

## Technical
- New database tables: journeys, transports, hotels, car_rentals, documents, notes, places_to_visit, reminders, expenses
- Database migration to schema version 2
- Document file handling in backup/restore
- App Group for Share Extension file transfer
- Proper reminder-notification linking with notificationId

