# Journey Wallet - Implementation Plan

## Overview

This document outlines the implementation plan for Journey Wallet iOS app features. The app allows users to manage journey details, bookings, documents, and travel history.

### Current State

**Already Implemented:**
- Database infrastructure (SQLite with migrations)
- iCloud backup/restore with automatic daily backups
- Export/Import functionality (JSON format)
- Notification system (local notifications)
- Localization (6 languages: EN, DE, RU, KK, TR, UK)
- Multi-currency support (11 currencies)
- Firebase Analytics
- Network monitoring
- Settings UI
- MVVM architecture

**To Be Implemented:**
- Journey management (CRUD). Journey can have multiple flights, hotels, car rentals, documents.
- Flight/Train/Bus/Transfer details
- Hotel details
- Car rental details
- Booking details
- Document storage (PDF, JPEG, PNG)
- Flight/journey reminders
- Statistics and travel history

## User stories

Below are some key user stories for the app:

1. As a user, I want to add a journey so that I can manage my travel plans.
2. As a user, I want to add transports to a journey so that I can track my travel itinerary.
3. As a user, I want to add hotels to a journey so that I can manage my accommodation.
4. As a user, I want to add car rentals to a journey so that I can track my car rental details.
5. As a user, I want to add documents to a journey so that I can store important travel documents.
6. As a user, I want to add notes to a journey so that I can add additional information.
7. As a user, I want to add places to visit to a journey so that I can plan my travel activities.
8. As a user, I want to add reminders to a journey so that I don't forget important travel details.
9. As a user, I want to add expenses to a journey so that I can track my travel expenses.
10. As a user, I want to have an option to open any file (PDF, JPEG, PNG, photo) via the system share sheet, so I can add the file to a selected journey. The file should be copied to the app's Documents directory and linked to the journey. *(Implemented via Share Extension - see Phase 8, Step 8.5)*
11. As a user, I want to view, delete, or share files (PDF, images) related to a journey within the app. *(Implemented via PDFKit for PDFs, UIImageView for images - see Phase 8, Step 8.4)*
12. As a user, I want to quickly add any entity (transport, hotel, car rental, document, note, place, reminder, expense) to the current journey via a floating "Add new..." button, so I can efficiently manage my travel details without navigating to each section. *(Implemented via Quick Add Feature - see Phase 4, Step 4.5)*

**Note:** This list is not exhaustive. Additional features may be identified during development.

## Features and Views

**Main tabs**
- Tab 1: MainView
  - Stats
  - Search anything
  - Active journies
- Tab 2: Journey details
  - Selector of the journey at the top of the View
  - Transport
  - Hotel
  - Car rental
  - Documents
  - Notes
  - Places to visit
  - Reminders
  - Budget
- Tab 3: All journeys
  - List of all journeys
  - CRUD operations
- Tab 5: Important notifications and reminders
- Tab 6: SettingsView

---

## Phase 1: Core Data Models & Database

**Goal:** Establish the data foundation for all journey-related features.

### Step 1.1: Create Journey Model
- Create `Journey.swift` model with properties:
  - `id: UUID`
  - `name: String` (trip name, e.g., "Paris Vacation 2025")
  - `destination: String`
  - `startDate: Date`
  - `endDate: Date`
  - `notes: String?`
  - `createdAt: Date`
  - `updatedAt: Date`
- Add Codable conformance for backup/export

### Step 1.2: Create TransportType Enum
- Create `TransportType.swift` enum:
  ```swift
  enum TransportType: String, Codable, CaseIterable {
      case flight
      case train
      case bus
      case ferry
      case transfer  // taxi, uber, private car
      case other
  }
  ```
- Each type has localized display name and SF Symbol icon

### Step 1.3: Create Transport Model
- Create `Transport.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `type: TransportType`
  - `carrier: String?` (airline, train company, bus company, etc.)
  - `transportNumber: String?` (flight number, train number, etc.)
  - `departureLocation: String`
  - `arrivalLocation: String`
  - `departureDate: Date`
  - `arrivalDate: Date`
  - `bookingReference: String?`
  - `seatNumber: String?`
  - `platform: String?` (terminal/platform/gate)
  - `cost: Decimal?`
  - `currency: Currency?`
  - `notes: String?`
- Add Codable conformance
- Add computed properties for type-specific labels (e.g., "Terminal" for flights, "Platform" for trains)

### Step 1.4: Create Hotel Model
- Create `Hotel.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `name: String`
  - `address: String`
  - `checkInDate: Date`
  - `checkOutDate: Date`
  - `bookingReference: String?`
  - `roomType: String?`
  - `cost: Decimal?`
  - `currency: Currency?`
  - `contactPhone: String?`
  - `notes: String?`
- Add Codable conformance

### Step 1.5: Create CarRental Model
- Create `CarRental.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `company: String`
  - `pickupLocation: String`
  - `dropoffLocation: String`
  - `pickupDate: Date`
  - `dropoffDate: Date`
  - `bookingReference: String?`
  - `carType: String?`
  - `cost: Decimal?`
  - `currency: Currency?`
  - `notes: String?`
- Add Codable conformance

### Step 1.6: Create Document Model
- Create `Document.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `name: String`
  - `fileType: DocumentType` (enum: pdf, jpeg, png, other)
  - `fileName: String`
  - `fileSize: Int64`
  - `createdAt: Date`
  - `notes: String?`
- Add Codable conformance
- Documents stored in app's Documents directory

### Step 1.7: Create Note Model
- Create `Note.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `title: String`
  - `content: String`
  - `createdAt: Date`
  - `updatedAt: Date`
- Add Codable conformance

### Step 1.8: Create PlaceToVisit Model
- Create `PlaceToVisit.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `name: String`
  - `address: String?`
  - `category: PlaceCategory` (enum: restaurant, attraction, museum, shopping, nature, other)
  - `isVisited: Bool`
  - `plannedDate: Date?`
  - `notes: String?`
  - `createdAt: Date`
- Add Codable conformance

### Step 1.9: Create Reminder Model
- Create `Reminder.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `title: String`
  - `reminderDate: Date`
  - `isCompleted: Bool`
  - `relatedEntityType: ReminderEntityType?` (enum: transport, hotel, carRental, place, custom)
  - `relatedEntityId: UUID?`
  - `notificationId: String?` (links to system notification)
  - `createdAt: Date`
- Add Codable conformance

### Step 1.10: Create Expense Model (for Budget)
- Create `Expense.swift` model with properties:
  - `id: UUID`
  - `journeyId: UUID`
  - `title: String`
  - `amount: Decimal`
  - `currency: Currency`
  - `category: ExpenseCategory` (enum: transport, accommodation, food, activities, shopping, other)
  - `date: Date`
  - `notes: String?`
  - `createdAt: Date`
- Add Codable conformance

### Step 1.11: Database Migration
- Create `Migration_20260117_JourneyTables.swift`
- Create tables: `journeys`, `transports`, `hotels`, `car_rentals`, `documents`, `notes`, `places_to_visit`, `reminders`, `expenses`
- Update schema version to 2
- Update `ExportModels.swift` to include new models

---

## Phase 2: Repositories & Data Access

**Goal:** Implement data access layer for all journey entities.

### Step 2.1: JourneysRepository
- Create `JourneysRepository.swift`
- Implement CRUD operations:
  - `createTable()`
  - `fetchAll() -> [Journey]`
  - `fetchById(id: UUID) -> Journey?`
  - `insert(_ journey: Journey)`
  - `update(_ journey: Journey)`
  - `delete(id: UUID)`
  - `deleteAll()`

### Step 2.2: TransportsRepository
- Create `TransportsRepository.swift`
- Implement CRUD operations:
  - `fetchByJourneyId(journeyId: UUID) -> [Transport]`
  - `fetchUpcoming() -> [Transport]` (for reminders)
  - `fetchByType(type: TransportType) -> [Transport]`
  - Standard CRUD methods

### Step 2.3: HotelsRepository
- Create `HotelsRepository.swift`
- Implement CRUD operations similar to TransportsRepository

### Step 2.4: CarRentalsRepository
- Create `CarRentalsRepository.swift`
- Implement CRUD operations similar to TransportsRepository

### Step 2.5: DocumentsRepository
- Create `DocumentsRepository.swift`
- Implement CRUD operations
- Add method to fetch documents by journey ID

### Step 2.6: NotesRepository
- Create `NotesRepository.swift`
- Implement CRUD operations
- Fetch notes by journey ID

### Step 2.7: PlacesToVisitRepository
- Create `PlacesToVisitRepository.swift`
- Implement CRUD operations
- Fetch by journey ID
- Toggle visited status

### Step 2.8: RemindersRepository
- Create `RemindersRepository.swift`
- Implement CRUD operations
- Fetch upcoming reminders (for notifications tab)
- Fetch by journey ID
- Mark as completed

### Step 2.9: ExpensesRepository
- Create `ExpensesRepository.swift`
- Implement CRUD operations
- Fetch by journey ID
- Calculate totals by category
- Calculate journey total spending

### Step 2.10: Update BackupService
- Update `ExportData` to include all new entities
- Update export/import logic to handle new entities
- Add document file handling for backup/restore

---

## Phase 3: Tab Structure & Main Views

**Goal:** Build the main tab navigation and core views.

### Step 3.1: Update MainTabView
- Update `MainTabView.swift` with 5 tabs:
  - Tab 1: MainView (home icon)
  - Tab 2: JourneyDetailView (suitcase icon)
  - Tab 3: JourneysListView (list icon)
  - Tab 4: NotificationsView (bell icon)
  - Tab 5: UserSettingsView (gear icon - already exists)
- Handle tab state and navigation

### Step 3.2: MainView (Tab 1 - Home/Dashboard)
- Create `MainView.swift`
- Sections:
  - **Stats cards**: Total journeys, upcoming trips, countries visited
  - **Search bar**: Search across all journeys, transports, hotels, places
  - **Active journeys**: List of current/upcoming journeys with quick access
- Create `MainViewModel.swift`

### Step 3.3: SearchService
- Create `SearchService.swift`
- Search across:
  - Journey names and destinations
  - Transport carriers and locations
  - Hotel names and addresses
  - Places to visit
  - Notes content
- Return unified search results

### Step 3.4: JourneysListView (Tab 3 - All Journeys)
- Create `JourneysListView.swift`
- Display list of all journeys with:
  - Journey name
  - Destination
  - Date range
  - Item count summary
- Sorting options (date, name, destination)
- Filter by status (upcoming, active, past)
- Add empty state view
- Swipe to delete
- Pull to refresh

### Step 3.5: JourneysListViewModel
- Create `JourneysListViewModel.swift`
- Implement:
  - `loadJourneys()`
  - `deleteJourney(id:)`
  - Sorting/filtering logic

### Step 3.6: JourneyFormView
- Create `JourneyFormView.swift`
- Form for creating/editing journeys
- Fields: name, destination, start/end dates, notes
- Date pickers with validation (end date >= start date)
- Used from both JourneysListView (create) and JourneyDetailView (edit)

---

## Phase 4: Journey Detail View (Tab 2)

**Goal:** Build the comprehensive journey detail view with all sub-sections.

### Step 4.1: JourneyDetailView Structure
- Create `JourneyDetailView.swift`
- **Journey selector** at top: Picker/dropdown to switch between journeys
- **Scrollable sections** below:
  - Transport section
  - Hotel section
  - Car rental section
  - Documents section
  - Notes section
  - Places to visit section
  - Reminders section
  - Budget section
- Each section shows summary with "See all" navigation

### Step 4.2: JourneyDetailViewModel
- Create `JourneyDetailViewModel.swift`
- Properties:
  - `selectedJourneyId: UUID?`
  - `journey: Journey?`
  - Summary counts for each section
- Methods:
  - `loadJourney(id:)`
  - `loadAllSectionData()`

### Step 4.3: JourneySelectorView
- Create `JourneySelectorView.swift`
- Dropdown/picker showing all journeys
- Display journey name and dates
- Quick create journey option
- Persists last selected journey

### Step 4.4: Section Summary Components
- Create reusable `SectionHeaderView.swift`
- Shows: section title, item count, "See all" button
- Consistent styling across all sections

### Step 4.5: Quick Add Feature
- **Goal:** Allow users to quickly add any entity type from the Journey Detail view
- **Implementation:**
  1. Add floating "Add new..." button (FAB) at the bottom-right of `JourneyDetailView`
  2. Create `QuickAddSheet.swift` - modal dialog with entity type selection
  3. Create `QuickAddEntityType` enum with cases:
     - `transport` - Transport (flight, train, bus, etc.)
     - `hotel` - Hotel
     - `carRental` - Car Rental
     - `document` - Document
     - `note` - Note
     - `place` - Place to Visit
     - `reminder` - Reminder
     - `expense` - Expense
  4. Display options in a grid or list with icons and localized names
  5. On selection, present the corresponding form view:
     - Transport → `TransportFormView`
     - Hotel → `HotelFormView`
     - Car Rental → `CarRentalFormView`
     - Document → `DocumentPickerView`
     - Note → `NoteFormView`
     - Place → `PlaceToVisitFormView`
     - Reminder → `ReminderFormView`
     - Expense → `ExpenseFormView`
  6. After successful save, dismiss both sheets and refresh the view
- **UI Design:**
  - Orange floating action button with "+" icon
  - Sheet with title "Add to Journey"
  - Grid layout (2 columns) with icon + label for each option
  - Each option uses consistent SF Symbol icons:
    - Transport: `airplane`
    - Hotel: `building.2.fill`
    - Car Rental: `car.fill`
    - Document: `doc.fill`
    - Note: `note.text`
    - Place: `mappin.circle.fill`
    - Reminder: `bell.fill`
    - Expense: `dollarsign.circle.fill`
- **Localization keys:**
  - `quick_add.title` = "Add to Journey"
  - `quick_add.transport` = "Transport"
  - `quick_add.hotel` = "Hotel"
  - `quick_add.car_rental` = "Car Rental"
  - `quick_add.document` = "Document"
  - `quick_add.note` = "Note"
  - `quick_add.place` = "Place to Visit"
  - `quick_add.reminder` = "Reminder"
  - `quick_add.expense` = "Expense"

---

## Phase 5: Transport Management

**Goal:** Implement transport booking management (flights, trains, buses, etc.).

### Step 5.1: TransportListView
- Create `TransportListView.swift`
- Display transports for a journey grouped by type
- Show departure/arrival info with type-specific icons
- Sort by departure date
- Filter by transport type

### Step 5.2: TransportDetailView
- Create `TransportDetailView.swift`
- Display transport details with type-specific layout:
  - Flights: airline, flight number, terminal, gate
  - Trains: train company, train number, platform
  - Buses: bus company, route number
  - Transfers: provider, vehicle type
- Show countdown to departure
- Quick actions (add reminder, copy booking ref)

### Step 5.3: TransportFormView
- Create `TransportFormView.swift`
- Dynamic form based on transport type selection
- Type picker (flight, train, bus, ferry, transfer, other)
- Type-specific field labels:
  - Flight: "Airline", "Flight Number", "Terminal"
  - Train: "Train Company", "Train Number", "Platform"
  - Bus: "Bus Company", "Route Number"
- Location/station/airport fields
- Date/time pickers

### Step 5.4: Transport Reminders
- Integrate with existing `NotificationManager`
- Add reminder options (24h, 3h, 1h before departure)
- **Important**: When creating reminders:
  1. First, schedule the local notification via `NotificationManager.shared.scheduleNotification()` to get the `notificationId`
  2. Then, create the `Reminder` entity with the returned `notificationId`
  3. Finally, insert the reminder into the database
- Store reminders in `reminders` table with `notificationId` for cancellation support
- Type-specific notification messages (e.g., "Your flight departs in 3 hours")

---

## Phase 6: Hotel Management

**Goal:** Implement hotel booking management.

### Step 6.1: HotelListView
- Create `HotelListView.swift`
- Display hotels for a journey
- Show check-in/check-out dates
- Sort by check-in date

### Step 6.2: HotelDetailView
- Create `HotelDetailView.swift`
- Display all hotel details
- Show nights count
- Quick actions (call hotel, copy booking ref)

### Step 6.3: HotelFormView
- Create `HotelFormView.swift`
- Form fields for all hotel properties
- Date pickers for check-in/check-out
- Address field with optional map link

### Step 6.4: Hotel Reminders
- Add reminder options (day before, 2 days before, week before check-in)
- **Important**: When creating reminders:
  1. First, schedule the local notification via `NotificationManager.shared.scheduleNotification()` to get the `notificationId`
  2. Then, create the `Reminder` entity with the returned `notificationId`
  3. Finally, insert the reminder into the database
- Store reminders in `reminders` table with `notificationId` for cancellation support

---

## Phase 7: Car Rental Management

**Goal:** Implement car rental management.

### Step 7.1: CarRentalListView
- Create `CarRentalListView.swift`
- Display car rentals for a journey
- Show pickup/dropoff info
- Sort by pickup date

### Step 7.2: CarRentalDetailView
- Create `CarRentalDetailView.swift`
- Display all rental details
- Show rental duration
- Quick actions (copy booking ref)

### Step 7.3: CarRentalFormView
- Create `CarRentalFormView.swift`
- Form fields for all rental properties
- Location fields
- Date/time pickers

### Step 7.4: Car Rental Reminders
- Add reminder options (day before, 2 days before, week before pickup)
- **Important**: When creating reminders:
  1. First, schedule the local notification via `NotificationManager.shared.scheduleNotification()` to get the `notificationId`
  2. Then, create the `Reminder` entity with the returned `notificationId`
  3. Finally, insert the reminder into the database
- Store reminders in `reminders` table with `notificationId` for cancellation support

---

## Phase 8: Document Management

**Goal:** Implement document storage and viewing.

### Step 8.1: DocumentService
- Create `DocumentService.swift`
- Implement file operations:
  - `saveDocument(data: Data, fileName: String) -> URL`
  - `loadDocument(fileName: String) -> Data?`
  - `deleteDocument(fileName: String)`
  - `getDocumentsDirectory() -> URL`
- Handle file naming conflicts

### Step 8.2: DocumentListView
- Create `DocumentListView.swift`
- Display documents for a journey
- Show file type icons
- Show file size
- Swipe to delete

### Step 8.3: DocumentPickerView
- Create `DocumentPickerView.swift`
- Use `UIDocumentPickerViewController`
- Support PDF, JPEG, PNG
- Handle file import

### Step 8.4: DocumentPreviewView
- Create `DocumentPreviewView.swift`
- **PDF Viewing**: Use `PDFKit` (`PDFView`) for native PDF rendering with zoom, scroll, page navigation
- **Image Viewing**: Use `UIImageView` wrapped in SwiftUI for JPEG/PNG display with pinch-to-zoom
- **Actions**: View, delete, share to other apps via `UIActivityViewController`
- Full-screen presentation with dismiss gesture

### Step 8.5: Share Extension (Import from System Share Sheet)
- **Create Share Extension target** in Xcode project
  - File > New > Target > Share Extension
  - Name: `JourneyWalletShare`
  - Configure for file types: PDF, JPEG, PNG, HEIC
- **ShareViewController.swift**
  - Extend `SLComposeServiceViewController` or use SwiftUI-based approach
  - Receive shared file via `NSExtensionContext`
  - Display journey picker to select target journey
  - Copy file to App Group shared container
  - Show success/error feedback
- **App Group Configuration**
  - Create App Group in Apple Developer Portal
  - Enable App Group capability in both main app and extension
  - Shared `UserDefaults` for passing journey selection
  - Shared container for file transfer between extension and main app
- **Main App Integration**
  - On app launch, check shared container for pending files
  - Process pending files and move to Documents directory
  - Link files to selected journey in database
  - Clean up shared container after processing
- **Info.plist Configuration**
  - Define `NSExtensionActivationRule` for supported file types
  - Set `NSExtensionPointIdentifier` to `com.apple.share-services`

### Step 8.6: Update Backup Service
- Add document files to iCloud backup
- Handle large file exports
- Progress indicator for document backup

---

## Phase 9: Notes, Places & Budget

**Goal:** Implement notes, places to visit, and budget tracking for journeys.

### Step 9.1: NotesListView
- Create `NotesListView.swift`
- Display notes for a journey
- Show title and preview of content
- Sort by date (newest first)
- Swipe to delete

### Step 9.2: NoteFormView
- Create `NoteFormView.swift`
- Title and content fields
- Rich text support (optional, basic markdown)
- Auto-save functionality

### Step 9.3: PlacesToVisitListView
- Create `PlacesToVisitListView.swift`
- Display places grouped by category
- Toggle visited/not visited status
- Filter by category
- Sort by planned date or name

### Step 9.4: PlaceToVisitFormView
- Create `PlaceToVisitFormView.swift`
- Fields: name, address, category, planned date, notes
- Category picker with icons
- Optional map integration for address

### Step 9.5: BudgetView (Expenses)
- Create `BudgetView.swift`
- Display:
  - Total budget/spending summary
  - Expenses list grouped by category
  - Visual breakdown (pie chart or bar)
- Add expense button

### Step 9.6: ExpenseFormView
- Create `ExpenseFormView.swift`
- Fields: title, amount, currency, category, date, notes
- Category picker
- Quick amount entry

---

## Phase 10: Reminders & Notifications (Tab 4)

**Goal:** Implement the notifications/reminders tab and reminder management.

### Step 10.1: NotificationsView (Tab 4)
- Create `NotificationsView.swift`
- Display all upcoming reminders across all journeys
- Grouped by date (Today, Tomorrow, This Week, Later)
- Show reminder title, related journey, and time
- Quick actions: mark complete, snooze, delete

### Step 10.2: ReminderFormView
- Create `ReminderFormView.swift`
- Fields: title, date/time, related entity (optional)
- Link to transport, hotel, car rental, or place
- Notification scheduling integration

### Step 10.3: ReminderService
- Create `ReminderService.swift`
- **Important**: When creating reminders:
  1. First, schedule the local notification via `NotificationManager.shared.scheduleNotification()` to get the `notificationId`
  2. Then, create the `Reminder` entity with the returned `notificationId`
  3. Finally, insert the reminder into the database
- When deleting reminders, use `notificationId` to cancel the scheduled notification
- Handle reminder completion (mark as completed, optionally cancel notification)
- Sync reminders with system notifications
- Auto-create reminders for transports (optional setting)

---

## Phase 11: Statistics Service

**Goal:** Provide travel insights and statistics for MainView.

### Step 11.1: StatisticsService
- Create `StatisticsService.swift`
- Calculate:
  - Total journeys count
  - Total transports count (by type)
  - Countries/cities visited
  - Total spending by category
  - Most visited destinations
  - Upcoming trips count

### Step 11.2: StatisticsWidgets
- Create reusable stat card components for MainView
- Quick stats: trips count, countries, total spent
- Integrate with MainView dashboard section

---

## Phase 12: Onboarding & Polish

**Goal:** Update onboarding and improve UX.

### Step 12.1: Update Onboarding Content
- Update `OnboardingViewModel.swift`
- Create journey-relevant onboarding pages:
  - Page 1: Track your journeys
  - Page 2: Store bookings & documents
  - Page 3: Get travel reminders (flights, trains, etc.)
  - Page 4: View travel statistics

### Step 12.2: Empty States
- Create consistent empty state views for:
  - No journeys
  - No transports in journey
  - No hotels in journey
  - No documents
  - No notes
  - No places to visit
  - No expenses

### Step 12.3: Loading States
- Add skeleton loading views
- Consistent loading indicators

### Step 12.4: Error Handling UI
- Create reusable error alert views
- Retry mechanisms

---

## Phase 13: Testing & Refinement

**Goal:** Ensure quality and stability.

### Step 13.1: Unit Tests
- Test all repositories
- Test ViewModels
- Test StatisticsService calculations
- Test ReminderService
- Test SearchService
- Test date calculations
- Test currency conversions

### Step 13.2: UI Testing
- Test critical user flows:
  - Create journey
  - Add transport (each type: flight, train, bus, etc.)
  - Add hotel, car rental
  - Add notes, places, expenses
  - Create and manage reminders
  - Import document via in-app picker
  - Import document via Share Extension (share from Files/Photos/Safari)
  - View PDF documents with PDFKit
  - View images with zoom/pan
  - Share documents to other apps
  - Backup/restore
  - Search functionality

### Step 13.3: Localization Review
- Verify all new strings are localized
- Review translations in all 6 languages
- Test RTL layout (if applicable)

### Step 13.4: Performance Testing
- Test with large datasets
- Optimize database queries
- Profile memory usage

### Step 13.5: Accessibility
- Add accessibility labels
- Test with VoiceOver
- Verify Dynamic Type support

---

## Implementation Priority

| Phase | Description | Priority | Effort |
|-------|-------------|----------|--------|
| Phase 1 | Data Models & Database | Critical | High |
| Phase 2 | Repositories & Data Access | Critical | Medium |
| Phase 3 | Tab Structure & Main Views | Critical | High |
| Phase 4 | Journey Detail View (Tab 2) | Critical | High |
| Phase 5 | Transport Management | High | High |
| Phase 6 | Hotel Management | High | Medium |
| Phase 7 | Car Rental Management | Medium | Medium |
| Phase 8 | Document Management & Share Extension | High | High |
| Phase 9 | Notes, Places & Budget | Medium | High |
| Phase 10 | Reminders & Notifications (Tab 4) | High | Medium |
| Phase 11 | Statistics Service | Medium | Low |
| Phase 12 | Onboarding & Polish | Low | Low |
| Phase 13 | Testing & Refinement | High | High |

---

## Notes

- Follow MVVM architecture as established in the codebase
- Use `Decimal` for all monetary values
- Localize all user-facing strings using `L()` function
- Support Dark Mode in all new views
- Use SF Symbols for icons
- Maintain orange as primary accent color
- All async operations should use async/await
- Add Firebase Analytics events for key actions
- **Reminder Creation Pattern**: Always schedule notification first to get `notificationId`, then create `Reminder` entity with that ID. This ensures proper linking between database records and system notifications for cancellation support.

---

## Future Considerations (Post-MVP)

- Calendar integration
- Trip sharing with other users
- Offline maps
- Currency conversion at time of booking
- Receipt scanning with OCR
- Real-time status tracking via APIs:
  - Flight status (FlightAware, AeroDataBox)
  - Train status (national rail APIs)
- Widgets for upcoming trips
- Apple Watch companion app
- Import bookings from email (parsing confirmation emails)
- Integration with booking platforms (Booking.com, Airbnb, etc.)
