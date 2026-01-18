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

## Localization

Supported languages: English (en), Russian (ru), Kazakh (kk), Turkish (tr), German (de), Ukrainian (uk)

Localization files are in `JourneyWallet/{lang}.lproj/Localizable.strings`.

## Currency

Monetary values must use `Decimal` type. Supported currencies are defined in `BusinessLogic/Models/Currency.swift`.

## Git Workflow

- Main branch: `main`
- Development branch: `develop`
- PRs target `develop` for review
