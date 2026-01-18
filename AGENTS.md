# AGENTS.md - "Journey Wallet" iOS App

## Project Overview

**App Name:** Journey Wallet  
**Platform:** iOS (iPhone, iPad)
**Minimum iOS Version:** 18.0  
**Language:** Swift 5.9+  
**UI Framework:** SwiftUI  
**Architecture:** MVVM  

### Purpose

The app allows users to manage their journey details, bookings, scans, notes, expenses, and track their travel history, and view their travel statistics.

---

## Tech Stack

### Core Technologies
- **SwiftUI** — All UI components
- **SwiftData** or **SQLite** — Local data persistence
- **Firebase Analytics** — Usage tracking and analytics
- **WidgetKit** — Home screen widgets
- **UserNotifications** — Local notifications

### Key Dependencies
- Firebase SDK (Analytics)
- Any SQLite wrapper if used (e.g., GRDB, SQLite.swift)

---

## Coding Standards

### Swift Style Guide

1. **Naming Conventions**
   - Use camelCase for variables, functions, and properties
   - Use PascalCase for types, protocols, and enums
   - Prefix private properties with `private` keyword, not underscore
   - Use descriptive names that convey intent

   ```swift
   // ✅ Good
   private var journeys: [Journey] = []
   func calculateTotalCost(for journeys: [Journey]) -> Decimal
   
   // ❌ Bad
   private var _journeys: [Any] = []
   func calc(s: [Journey]) -> Double
   ```

2. **Use Strong Types**
   - Prefer `Decimal` for monetary values, not `Double`
   - Use `Measurement<UnitEnergy>` for kWh values when appropriate
   - Use enums for fixed sets of values

   ```swift
   // ✅ Good
   struct Journey {
       let cost: Decimal
       let energyAdded: Double // kWh
       let travelType: TravelType
   }
   
   enum TravelType: String, Codable, CaseIterable {
       case flight
       case train
       case bus
       case car
   }
   ```

3. **SwiftUI Views**
   - Keep views small and focused (max ~100 lines)
   - Extract reusable components into separate views
   - Use `@ViewBuilder` for conditional view composition
   - Prefer composition over inheritance

   ```swift
   // ✅ Good - Extracted component
   struct JourneyRow: SwiftUI.View {
       let journey: Journey
       
       var body: some SwiftUI.View {
           HStack {
               // content
           }
       }
   }
   ```

4. **MVVM Pattern**
   - Views should not contain business logic
   - ViewModels handle data transformation and business logic
   - Use `@Observable` (iOS 17+) or `ObservableObject` for ViewModels
   - Keep ViewModels testable (inject dependencies)

   ```swift
   @Observable
   final class SessionsViewModel {
       private let databaseService: DatabaseServiceProtocol
       
       var journeys: [Journey] = []
       var isLoading = false
       var errorMessage: String?
       
       init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
           self.databaseService = databaseService
       }
       
       func loadSessions() async {
           isLoading = true
           defer { isLoading = false }
           
           do {
               journeys = try await databaseService.fetchJourneys()
           } catch {
               errorMessage = error.localizedDescription
           }
       }
   }
   ```

5. **Error Handling**
   - Use Swift's `Error` protocol for custom errors
   - Handle errors gracefully with user-friendly messages
   - Log errors for debugging (but not sensitive data)

   ```swift
   enum DatabaseError: LocalizedError {
       case fetchFailed
       case saveFailed
       case notFound
       
       var errorDescription: String? {
           switch self {
           case .fetchFailed: return String(localized: "error.fetch_failed")
           case .saveFailed: return String(localized: "error.save_failed")
           case .notFound: return String(localized: "error.not_found")
           }
       }
   }
   ```

6. **Async/Await**
   - Use modern Swift concurrency (async/await)
   - Mark main-thread operations with `@MainActor`
   - Use `Task` for launching async work from sync contexts

   ```swift
   // ✅ Good
   func loadData() async throws -> [Journey] {
       try await databaseService.fetchJourneys()
   }
   
   // In View
   .task {
       await viewModel.loadJourneys()
   }
   ```

---

## Localization

The app supports multiple languages:

- **English** (en) — Base
- **Russian** (ru)
- **Kazakh** (kk)
- **Turkish** (tr)
- **German** (de)

### Localization Rules

1. **Never hardcode user-facing strings**
   ```swift
   // ✅ Good
   Text(L("journeys.title"))
   Text(L("Journeys"))

   // ❌ Bad
   Text("Journeys")
   ```

2. **Use String Catalogs** (`.xcstrings`)
   - All strings go in `Localizable.xcstrings`
   - Use descriptive keys with dot notation: `journey.title`

3. **Handle pluralization properly**
   ```swift
   Text("journeys.count \(count)")
   // In xcstrings: use plural variations
   ```

4. **Format numbers and dates for locale**
   ```swift
   let formattedCost = cost.formatted(.currency(code: userCurrency))
   let formattedDate = date.formatted(date: .abbreviated, time: .shortened)
   ```

---

## UI/UX Guidelines

1. **Follow iOS Human Interface Guidelines**
2. **Use SF Symbols** for icons (prefer filled variants for tab bars)
3. **Support Dark Mode** — test all views in both modes
4. **Support Dynamic Type** — use system fonts and avoid fixed sizes
5. **Provide haptic feedback** for important actions
6. **Use system colors** when possible (`Color(.systemBackground)`, etc.)

### Color Palette
- Primary accent: Orange
- Use semantic colors for states (red for errors, green for success)

### Form Styling
```swift
// Standard form appearance
Form {
    Section {
        // content
    }
    .listRowBackground(Color(.secondarySystemGroupedBackground))
}
.scrollContentBackground(.hidden)
.background(Color(.systemGroupedBackground))
```

---

## Testing Requirements

1. **Unit Tests**
   - Test all ViewModel logic
   - Test data transformations
   - Test calculations (cost per kWh, statistics, etc.)

2. **Naming Convention**
   ```swift
   func test_calculateTotalCost_withMultipleJourneys_returnsCorrectSum()
   ```

3. **Test Coverage**
   - Aim for 80%+ coverage on business logic
   - All currency calculations must be tested

---

## Code Review Checklist

Before submitting code, ensure:

- [ ] No hardcoded strings (all localized)
- [ ] No force unwrapping (`!`) unless absolutely safe
- [ ] No `print()` statements (use proper logging)
- [ ] Decimal used for money, not Double
- [ ] Async operations use async/await
- [ ] Views are small and focused
- [ ] Dark mode tested
- [ ] Memory leaks checked (no retain cycles)
- [ ] Accessibility labels added for important elements

---

## Common Patterns

### Database Access
```swift
protocol DatabaseServiceProtocol {
    func fetchJourneys() async throws -> [Journey]
    func saveJourney(_ journey: Journey) async throws
    func deleteJourney(id: UUID) async throws
}
```

### Repository Access in Views

When a SwiftUI view needs to access a repository (e.g., for fetching user settings), **create a private field** in the view to hold the repository reference. Initialize it from `DatabaseManager.shared` in the view's `init()`. Do NOT call the chain directly in view code.

```swift
// ✅ Correct - Private repository field
struct BudgetView: View {
    let journeyId: UUID
    private let userSettingsRepository: UserSettingsRepository?

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self.userSettingsRepository = DatabaseManager.shared.userSettingsRepository
    }

    var body: some View {
        // Use the private field
        let currency = userSettingsRepository?.fetchCurrency() ?? .usd
        // ...
    }
}

// ❌ Wrong - Direct chain access in view code
struct BudgetView: View {
    var body: some View {
        // Don't do this:
        let currency = DatabaseManager.shared.userSettingsRepository?.fetchCurrency() ?? .usd
    }
}
```

This pattern:
- Keeps code cleaner and more readable
- Makes dependencies explicit and easier to test
- Avoids repeated long chain calls throughout the view

### Navigation
Use `NavigationStack` with type-safe navigation:
```swift
@Observable
final class Router {
    var path = NavigationPath()
    
    func navigate(to destination: Destination) {
        path.append(destination)
    }
}
```

### Dependency Injection
```swift
// Use protocol-based DI for testability
final class SessionsViewModel {
    private let database: DatabaseServiceProtocol
    
    init(database: DatabaseServiceProtocol = DatabaseService.shared) {
        self.database = database
    }
}
```

---

## Don'ts

1. **Don't use `AnyView`** — it hurts performance
2. **Don't use `@EnvironmentObject`** excessively — prefer explicit passing
3. **Don't ignore errors** — always handle or propagate
4. **Don't use `Double` for currency** — use `Decimal`
5. **Don't skip localization** — even for "temporary" strings
6. **Don't use `Timer`** — use `Task.sleep` or `.task` modifier
7. **Don't hardcode App Store ID** — use constants file
8. **Don't commit API keys** — use xcconfig or environment variables
9. **Don't call `DatabaseManager.shared.someRepository?.method()` chains directly in view code** — use a private repository field initialized in `init()` instead (see "Repository Access in Views" pattern above)
10. **Don't use non-existent static fields** — repositories don't have `.shared` static fields; always access them via `DatabaseManager.shared.repositoryName`

---

## Helpful Commands

```bash
# Generate localized screenshots
xcodebuild -scheme JourneyWallet -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test

# Lint code
swiftlint lint --strict

# Format code
swiftformat .
```

---

## Resources

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

---

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
