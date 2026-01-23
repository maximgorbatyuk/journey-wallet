# Changelog

# 2026.1.2 (2026-01-22)

## New Features

### Share Extension
- Share files directly from other apps (Mail, Files, Safari, etc.) to Journey Wallet
- Select which journey to add the document to from the Share sheet
- Optionally set a custom display name for the document
- Supports PDFs and images (JPEG, PNG, HEIC)
- Share up to 10 files at once

### Color Scheme Selector
- Choose between Dark, Light, or System appearance mode
- System mode follows device settings automatically
- Preference saved to database and persists across sessions
- Available in Settings → Base Settings

## Improvements

### User Settings
- Added color scheme picker with icons for each mode
- Improved journey picker UI - hides empty destination text
- Developer mode: Added "View user_settings table" for debugging
- Developer mode: Added "Reset App Group Migration Flag" button for testing

### Data Migration
- Database automatically migrates to shared App Group container on first launch
- Documents folder migrates to shared container
- Enables seamless data access between main app and Share Extension
- Migration runs once and is tracked to prevent re-running

### Localization
- Added translations for Share Extension UI in all 6 languages (EN, RU, DE, UK, TR, KK)
- Added color scheme labels in all languages

## Technical

### Share Extension Architecture
- Single ShareExtension target with xcconfig-based configuration
- Dynamic bundle ID and App Group based on build configuration (Debug/Release)
- Separate entitlements files for Debug and Release builds
- Extension shares database and documents with main app via App Group

### New Files
- `ShareExtension/` - Share Extension target files
- `BusinessLogic/Helpers/AppGroupContainer.swift` - Shared container access helper
- `BusinessLogic/Database/DatabaseMigrationHelper.swift` - One-time migration utility
- `JourneyWallet/Services/ColorSchemeManager.swift` - Color scheme persistence
- `docs/plans/SHARE_EXTENSION_PLAN.md` - Share Extension documentation

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

