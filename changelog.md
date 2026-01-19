# Changelog

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

