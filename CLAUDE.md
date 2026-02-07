# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Journey Wallet is an iOS app for managing travel plans, bookings, documents, and expenses. The app is in active development with core infrastructure complete and journey management features being implemented.

- **Platform:** iOS 18.0+
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Database:** SQLite (using SQLite.swift library)

## Build and Development Commands

```bash
# Build the project
xcodebuild -project JourneyWallet.xcodeproj -scheme JourneyWallet \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Run tests with coverage
./run_tests.sh

# Format code (requires SwiftFormat: brew install swiftformat)
./scripts/run_format.sh

# Lint code (requires SwiftLint: brew install swiftlint)
./scripts/run_lint.sh

# Run all quality checks (format, lint, tests)
./scripts/run_all_checks.sh

# Detect unused code (requires Periphery: brew install peripheryapp/periphery/periphery)
./scripts/detect_unused_code.sh
```

## Architecture

### Directory Structure

- **JourneyWallet/** - Main app target containing UI views and view models
  - `JourneyWalletApp.swift` - App entry point with onboarding flow
  - `MainTabView.swift` - Tab navigation controller
  - Language directories (`en.lproj/`, `ru.lproj/`, etc.) - Localization files
- **BusinessLogic/** - Shared business logic layer
  - `Database/` - SQLite database manager, repositories, and migrations
  - `Models/` - Data models (Currency, UserSettings, etc.)
  - `Services/` - App services (Analytics, Backup, Notifications, Localization, etc.)
  - `Errors/` - Error types and logging

### Key Patterns

**Localization:** Use the global `L()` function for all user-facing strings:
```swift
Text(L("key.name"))  // Not Text("Hardcoded string")
```

**Database Access:** Repositories handle data operations via `DatabaseManager.shared`:
```swift
// In ViewModels or Services - direct access is OK
DatabaseManager.shared.userSettingsRepository?.fetchSettings()

// In SwiftUI Views - use private repository field pattern
struct MyView: View {
    private let userSettingsRepository: UserSettingsRepository?

    init() {
        self.userSettingsRepository = DatabaseManager.shared.userSettingsRepository
    }

    var body: some View {
        // Use the field, not the chain:
        let currency = userSettingsRepository?.fetchCurrency() ?? .usd
    }
}
```

**Important:** Never use non-existent static fields like `UserSettingsRepository.shared` — repositories don't have `.shared` accessors. Always get them from `DatabaseManager.shared`.

**Analytics:** Use `AnalyticsService.shared.trackEvent()` for tracking. Firebase is only configured in Release builds.

**ViewModels:** Use `@Observable` pattern with dependency injection for testability.

**Detail View Pattern:** Detail views (e.g., `CarRentalDetailView`, `TransportDetailView`, `HotelDetailView`) must follow the MVVM pattern with corresponding ViewModels:

```swift
// ViewModel handles all database operations
@MainActor
@Observable
class EntityDetailViewModel {
    var entity: Entity
    let journeyId: UUID

    private let entityRepository: EntityRepository?
    private let remindersRepository: RemindersRepository?
    private let logger: Logger

    init(entity: Entity, journeyId: UUID, databaseManager: DatabaseManager = .shared) {
        self.entity = entity
        self.journeyId = journeyId
        self.entityRepository = databaseManager.entityRepository
        self.remindersRepository = databaseManager.remindersRepository
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "EntityDetailViewModel")
    }

    func updateEntity(_ updated: Entity) { ... }
    func deleteEntity() -> Bool { ... }  // Also deletes associated reminders
    func saveReminder(date: Date, title: String) { ... }
}

// View only handles UI presentation
struct EntityDetailView: View {
    @State private var viewModel: EntityDetailViewModel

    init(entity: Entity, journeyId: UUID) {
        _viewModel = State(initialValue: EntityDetailViewModel(entity: entity, journeyId: journeyId))
    }

    var body: some View {
        // Access data via viewModel.entity
        // Call viewModel methods for actions
    }
}

// Reminder sheets receive the parent ViewModel
struct EntityReminderSheet: View {
    let viewModel: EntityDetailViewModel

    // Use viewModel.saveReminder() for creating reminders
}
```

**Important:** Views should NEVER directly access repositories. All database operations must go through ViewModels.

## Localization

Supported languages: English (en), Russian (ru), Kazakh (kk), Turkish (tr), German (de), Ukrainian (uk)

Localization files are in `JourneyWallet/{lang}.lproj/Localizable.strings`.

Before adding any localization strings (NSLocalizedString, etc.), verify the translation key exists in all .strings/.xcstrings files. Never add untranslated keys without flagging them.

### Navigation
Use `NavigationStack` for all navigation containers. Never use `NavigationView` — it is deprecated and causes layout issues (unwanted split view on iPad in sheets).

## Currency

Monetary values must use `Decimal` type. Supported currencies are defined in `BusinessLogic/Models/Currency.swift`.

## Documentation

When editing existing documentation (README.md, CHANGELOG.md, etc.), preserve the original content and structure. Only add or modify the specific sections relevant to the task. Do not rewrite existing text.

## Pagination

When implementing pagination or filtering, always default to SQL-level implementation unless explicitly told otherwise. Never implement in-memory pagination for data that comes from a database.

## List Reordering with @Observable

SwiftUI's `List` suppresses `@Observable`-driven re-renders during `.onMove` gesture processing. Never mutate an `@Observable` array directly in `.onMove` — the UI won't update.

**Fix:** Use a local `@State` array for `ForEach`, mutate it directly in `.onMove`, and sync with the ViewModel via `onChange(of:)`. The ViewModel only handles DB persistence; visual reordering is driven by `@State`.

```swift
@State private var localItems: [Item] = []

List {
    ForEach(localItems) { item in ... }
        .onMove { source, destination in
            localItems.move(fromOffsets: source, toOffset: destination)
            viewModel.persistReorder(localItems)
        }
}
.onChange(of: viewModel.items) { _, newItems in
    localItems = newItems
}
```

## Git Workflow

- Main branch: `main`
- Development branch: `develop`
- PRs target `develop` for review

## Agent Instructions

When generating code for this project:

1. **Always ask for clarification** if requirements are ambiguous
2. **Provide complete, runnable code** — no placeholders or TODOs unless requested
3. **Include error handling** in all async operations
4. **Add brief comments** for complex logic only
5. **Follow existing patterns** in the codebase
6. **Consider edge cases**: empty states, loading states, error states
7. **Suggest tests** for critical business logic
8. **Respect the localization requirement** — never hardcode strings

When modifying existing code:
1. Understand the current implementation first
2. Make minimal changes to achieve the goal
3. Maintain consistency with surrounding code style
4. Don't refactor unrelated code unless asked