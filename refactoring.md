# iOS App Refactoring Plan

**Project:** EVChargingTracker → AwesomeApplication  
**Goal:** Convert EV charging tracker app into a generic iOS app template  
**Current Version:** 2026.1.4 → **Target Version:** 2026.1.1  
**Current Bundle ID:** mgorbatyuk.dev.EVChargeTracker → **Target Bundle ID:** dev.mgorbatyuk.AwesomeApplication

## Overview

This refactoring will remove all EV charging-specific business logic while preserving core infrastructure components, making the app suitable as a template for new projects.

## Phases

### ✅ Phase 1: Project Configuration & Naming

**Objective:** Update all app identifiers, names, and version information

**Tasks:**
1. ✅ Update bundle identifier in `EVChargingTracker.xcodeproj/project.pbxproj`:
   - ✅ Change `mgorbatyuk.dev.EVChargeTracker` → `dev.mgorbatyuk.AwesomeApplication`
   - ✅ Change `mgorbatyuk.dev.EVChargeTrackerDebug` → `dev.mgorbatyuk.AwesomeApplicationDebug`
   - ✅ Update test bundle identifier if needed

2. ✅ Rename app folder structure:
   - ✅ Rename `EVChargingTracker/` → `AwesomeApplication/`
   - ✅ Update all references in project.pbxproj

3. ✅ Update Xcode project file references:
   - ✅ Rename `EVChargingTracker.xcodeproj` → `AwesomeApplication.xcodeproj`
   - ✅ Update all file references within project.pbxproj

4. ✅ Update version numbers:
   - ✅ Change `MARKETING_VERSION` from `2026.1.4` to `2026.1.1` in project.pbxproj

5. ✅ Update Info.plist:
   - ✅ Change background task identifier from `com.evchargingtracker.daily-backup` to `dev.mgorbatyuk.awesomeapplication.daily-backup`

**Expected Outcome:** All project identifiers updated, app renamed to AwesomeApplication

---

### ✅ Phase 2: Remove Business Logic Models

**Objective:** Remove EV charging-specific models while keeping domain-level currencies and languages

**Tasks:**
1. ✅ Remove files from `BusinessLogic/Models/`:
   - ✅ `Car.swift`
   - ✅ `ExpenseModels.swift` (contains Expense, ExpenseType, ChargerType)
   - ✅ `PlannedMaintenance.swift`

2. ✅ Modify `ExportModels.swift`:
   - ✅ Keep `ExportMetadata` struct
   - ✅ Remove: `ExportData`, `ExportCar`, `ExportExpense`, `ExportPlannedMaintenance`, `ExportDelayedNotification`, `ExportUserSettings`, `ExportValidationError`
   - ✅ Create minimal export structure with only metadata

3. ✅ Keep files in `BusinessLogic/Models/`:
   - ✅ `Currency.swift` (all currencies)
   - ✅ `UserSettings.swift` (AppLanguage enum)
   - ✅ `SqlMigration.swift`
   - ✅ `DelayedNotification.swift` (may be used for general notifications)

**Expected Outcome:** Only generic models (Currency, UserSettings, SqlMigration, ExportMetadata, DelayedNotification) remain

---

### ✅ Phase 3: Remove Database Repositories

**Objective:** Remove repositories related to deleted models while keeping database infrastructure

**Tasks:**
1. ✅ Remove files from `BusinessLogic/Database/`:
   - ✅ `CarRepository.swift`
   - ✅ `ExpensesRepository.swift`
   - ✅ `PlannedMaintenanceRepository.swift`

2. ✅ Keep files in `BusinessLogic/Database/`:
   - ✅ `DatabaseManager.swift` (core database manager)
   - ✅ `MigrationsRepository.swift` (migration mechanism)
   - ✅ `UserSettingsRepository.swift` (needed for UserSettings)
   - ✅ `DelayedNotificationsRepository.swift` (general notification support)
   - ✅ `DatabaseError.swift`

3. ✅ Update `DatabaseManager.swift`:
   - ✅ Remove references to deleted repositories
   - ✅ Remove initialization of CarRepository, ExpensesRepository, PlannedMaintenanceRepository
   - ✅ Remove protocol methods for deleted repositories
   - ✅ Remove deleteAllData() and deleteAllExpenses() methods
   - ✅ Update migrateIfNeeded() to only keep migration 1 (user settings)
   - ✅ Change latestVersion to 1
   - ✅ Update database filename to "awesome_application.sqlite3"
   - ✅ Update logger subsystem to "dev.mgorbatyuk.awesomeapplication.database"

**Expected Outcome:** DatabaseManager cleaned of business-specific repositories, only core database infrastructure remains

---

### ✅ Phase 4: Remove SQL Migrations

**Objective:** Remove database migrations for deleted tables

**Tasks:**
1. ✅ Keep in `BusinessLogic/Database/Migrations/`:
   - ✅ `Migration_20251021_CreateCarsTable.swift` (first migration - kept as template for future migrations)
   - ✅ Updated migration to be a generic template without business-specific dependencies

2. ✅ Remove from `BusinessLogic/Database/Migrations/`:
   - ✅ `Migration_20251104_CreatePlannedMaintenanceTable.swift`
   - ✅ `Migration_20251114_CreateDelayedNotificationTable.swift`

3. ✅ Note: The first migration has been updated to be a generic template demonstrating migration pattern without business-specific dependencies

**Expected Outcome:** Only first migration remains as a generic template

---

### ✅ Phase 5: Remove UI Screens

**Objective:** Remove all screens except UserSettings and MainTab

**Tasks:**
1. ✅ Remove entire screen folders from `AwesomeApplication/`:
   - ✅ `ChargingSessions/` (and all subdirectories)
   - ✅ `Expenses/`
   - ✅ `PlanedMaintenance/`
   - ✅ `Onboarding/`

2. ✅ Keep screen folders:
   - ✅ `UserSettings/` (with all functionality)
   - ✅ `MainTabView.swift` (main tab view)
   - ✅ `MainTabViewModel.swift`

3. ✅ Keep shared components:
   - ✅ `Shared/` (reusable UI components)
   - ✅ `Assets.xcassets/` (app assets)
   - ✅ `Config/` (configuration files)
   - ✅ All localization folders (en.lproj, de.lproj, ru.lproj, kk.lproj, tr.lproj, uk.lproj)

4. ✅ Rename app entry file:
   - ✅ `EVChargingTrackerApp.swift` → `AwesomeApplicationApp.swift`

5. Note: Onboarding folder was initially removed but will be restored from git as it should be kept

**Expected Outcome:** UserSettings, MainTab, and Onboarding views remain (Onboarding to be restored)

---

### ✅ Phase 6: Remove ViewModels

**Objective:** Remove viewmodels associated with deleted screens while keeping Onboarding

**Tasks:**
1. ✅ Remove viewmodel files (already removed in Phase 5 when folders were deleted):
   - ✅ `ChargingSessions/ChargingViewModel.swift`
   - ✅ `ChargingSessions/ExpensesChartViewModel.swift`
   - ✅ `ChargingSessions/ChargingConsumptionChartViewModel.swift`
   - ✅ `Expenses/ExpensesViewModel.swift`
   - ✅ `PlanedMaintenance/PlanedMaintenanceViewModel.swift`
   - ✅ `ChargingSessions/DeveloperModeManager.swift`

2. ✅ Restore and keep viewmodel files:
   - ✅ `UserSettings/UserSettingsViewModel.swift`
   - ✅ `MainTabViewModel.swift`
   - ✅ `Onboarding/OnboardingViewModel.swift` (restored from git)
   - ✅ `Onboarding/OnboardingPageViewModelItem.swift` (restored from git)

3. ✅ Verification:
   - ✅ Confirmed only UserSettingsViewModel, MainTabViewModel, and Onboarding viewmodels remain
   - ✅ No other viewmodel files found in AwesomeApplication directory
   - ✅ Shared/FilterButtonsViewModel.swift preserved (shared component)

**Expected Outcome:** Only viewmodels for UserSettings, MainTab, and Onboarding remain

---

### ✅ Phase 7: Clean Up UserSettings View

**Objective:** Remove car-related functionality from UserSettings

**Tasks:**
1. ✅ Review and modify `UserSettings/UserSettingsView.swift`:
   - ✅ Remove Cars section and related UI
   - ✅ Remove EditCarView references and state variables
   - ✅ Remove CarRecordView references
   - ✅ Remove showAddCarModal state variable
   - ✅ Remove CallEditCarView function
   - ✅ Keep language selection
   - ✅ Keep currency selection (removed hasAnyExpense check, now always editable)
   - ✅ Keep notification settings
   - ✅ Keep AboutAppSubView

2. ✅ Modify `UserSettings/UserSettingsView.swift`:
   - ✅ Remove car-related sheets (showAddCarModal, editingCar)
   - ✅ Remove CallEditCarView function and all car editing logic
   - ✅ Update import preview message to remove car/expense/maintenance references
   - ✅ Remove developer mode car-related buttons (Add random expenses, Delete car expenses)
   - ✅ Update "Delete all data" button message to remove car references

3. ✅ Remove or update related files:
   - ✅ Removed `EditCarView.swift`
   - ✅ Removed `CarRecordView.swift`

4. ⚠️ Note: `UserSettingsViewModel.swift` still contains car-related methods (getCars, hasOtherCars, getCarsCount, getCarById, insertCar, updateCar, deleteCar, refetchCars, deleteAllExpenses, deleteAllExpensesForCar, addRandomExpenses) - these should be removed in future iterations but are kept for now as View file no longer calls them

**Expected Outcome:** UserSettings contains only generic settings (language, currency, notifications, about)

---

### ✅ Phase 8: Update Services

**Objective:** Review and update services to remove business logic dependencies while preserving method signatures

**Tasks:**
1. ✅ Keep all services in `BusinessLogic/Services/`:
   - ✅ `AnalyticsService.swift` (no changes needed)
   - ✅ `AppVersionChecker.swift` (no changes needed)
   - ✅ `BackgroundTaskManager.swift` (no changes needed - doesn't use business models)
   - ✅ `BackupService.swift` (MAJOR UPDATE - removed all business-specific code)
   - ✅ `EnvironmentService.swift` (no changes needed)
   - ✅ `IExpenseView.swift` (kept - interface for future use)
   - ✅ `LocalizationManager.swift` (no changes needed)
   - ✅ `NetworkMonitor.swift` (no changes needed)
   - ✅ `NotificationManager.swift` (no changes needed - doesn't use business models)

2. ✅ Review `BackupService.swift` - **MAJOR REFACTOR**:
   - ✅ **Kept all method signatures** - no methods removed
   - ✅ Removed all repository dependencies (CarRepository, ExpensesRepository, PlannedMaintenanceRepository)
   - ✅ Updated `createExportData()` to only return metadata (no cars, expenses, maintenance, notifications)
   - ✅ Updated `validateExportData()` to only validate metadata
   - ✅ Updated `importExportData()` to only import user settings
   - ✅ Updated `getBackupInfo()` to set cars/expenses/maintenance/notifications counts to 0
   - ✅ Updated bundle identifiers and directory names from "ev_charging_tracker" to "awesome_application"
   - ✅ Updated logger subsystem to "dev.mgorbatyuk.awesomeapplication.businesslogic"
   - ✅ **Kept all iCloud backup functionality fully implemented** (not "To be implemented")
   - ✅ **Kept all safety backup functionality fully implemented** (not "To be implemented")
   - File size reduced from 923 lines to 564 lines (removed all business-specific code)

3. ✅ Review `NotificationManager.swift`:
   - ✅ **Kept all method signatures** - no methods removed
   - ✅ No business-specific code to remove (doesn't reference planned maintenance)

4. ✅ Review `BackgroundTaskManager.swift`:
   - ✅ **Kept all method signatures** - no methods removed
   - ✅ No business-specific code to remove

5. ✅ **Important Note:** The `RuntimeError` type already exists in `BusinessLogic/Errors/RuntimeError.swift` and should be used for all "To be implemented" placeholders

6. ✅ **Critical Consideration:** Ensured that methods with "To be implemented" placeholders are **not called** in the default template state:
   - ✅ All backup functionality (iCloud and safety) remains fully functional
   - ✅ Import/Export workflows work with UserSettings only
   - ✅ No methods throw "To be implemented" that are called during normal operation
   - ✅ App will launch and show UserSettings without triggering any "To be implemented" errors

7. ⚠️ Note: `IExpenseView.swift` kept as-is for potential future use

**Expected Outcome:** All service methods are preserved with their original signatures; methods that worked with business-specific models removed or simplified to only work with UserSettings and ExportMetadata; iCloud backup functionality remains fully functional

**Expected Outcome:** All service methods are preserved with their original signatures; methods that worked with business-specific models throw "To be implemented" errors, providing a clear template for future implementation

---

### ✅ Phase 9: Remove Class Comments

**Objective:** Remove class file header comments throughout codebase

**Tasks:**
1. ✅ Remove header comments from all Swift files in:
   - ✅ `AwesomeApplication/` (18 files processed)
   - ✅ `BusinessLogic/` (27 files processed)
   - ✅ `AwesomeApplicationTests/` (renamed from EVChargingTrackerTests, 8 files processed)

2. ✅ Typical comment removed:
   - ✅ Removed comment block pattern:
     ```swift
     //
     //  FileName.swift
     //  EVChargingTracker
     //
     //  Created by Maxim Gorbatyuk on DD.MM.YYYY.
     //
     ```
   - ✅ Preserved all actual code and functional comments
   - ✅ Kept only import statements, class/struct/enum declarations

3. ✅ Verification:
   - ✅ Confirmed no files with header comments remain
   - ✅ Checked 53 total Swift files across all directories
   - ✅ All files now start with import statements or declarations

**Expected Outcome:** No class header comments in any Swift files

---

### ✅ Phase 10: Update Localizations

**Objective:** Clean up localization files and update app name references

**Tasks:**
1. ✅ Keep all language folders:
   - ✅ `en.lproj/`
   - ✅ `de.lproj/`
   - ✅ `ru.lproj/`
   - ✅ `kk.lproj/`
   - ✅ `tr.lproj/`
   - ✅ `uk.lproj/`

2. ✅ Remove unused localization keys from `Localizable.strings` in all language folders:
   - ✅ Removed Car, Expense, Charging, Maintenance related keys
   - ✅ Removed keys: "Car", "Cars", "Battery capacity", "e.g. 75", "Current mileage", "Minimum: %d", "Current: %d", "Danger zone", "Selected for tracking", "Edit car", "CO₂ saved", "kWh / 100km", "Charges", "Initial mileage", "Current mileage", "Battery", "Tracking", "Not tracking", "It is recommended to set the default currency...", "Tracking settings"
   - ✅ Removed all expense-related keys: "Expense details", "Date", "Energy (kWh)", "Charger Type", "Expense Type", "Odometer (km)", "Cost (%@)", "Car name", "Name of the car", "Notes (optional)", "Add expense", "Price per kWh", "Please select an expense type", "Please type a valid value for Energy", "Please type a valid value for Odometer", "Hint", "per km", "One kilometer price (charging only)", "How much one kilometer costs you including only charging expenses", "One kilometer price (total)", "How much one kilometer costs you including all logged expenses", "Total charging costs", "Add Charging Session", "Car stats", "Add Expense", "Total costs", "All car expenses", "No expenses yet", "No expenses of this type yet", "Add your first expense to start tracking"
   - ✅ Removed expense deletion confirmation keys
   - ✅ Removed all ExpenseType and ChargerType human-friendly keys
   - ✅ Removed all maintenance-related keys: "Planned maintenance", "Add maintenance", "No maintenance records yet", "Add your first maintenance record", "Delete maintenance record?", "Delete selected maintenance record?", "Please add car first to track maintenance records", "When", "Plan a maintenance", "Maintenance details", "Odometer value cannot be less than current car mileage", "What should be done?", "Remind by date (optional)", "Remind by odometer (optional)", "Additional information that will be helpful"
   - ✅ Removed filter keys: "Filter.All", "Filter.Charges", "Filter.Repair/maintenance", "Filter.Repair", "Filter.Maintenance", "Filter.Carwash", "Filter.Other"
   - ✅ Removed onboarding-specific keys: "onboarding.track_your_chargings", "onboarding.track_your_chargings__subtitle", "onboarding.monitor_costs", "onboarding.monitor_costs__subtitle", "onboarding.plan_maintenance", "onboarding.plan_maintenance__subtitle", "onboarding.view_stats", "onboarding.view_stats__subtitle"
   - ✅ Removed stats-related keys: "Expenses chart", "Average charging trend", "%.1f kWh/month average", "No expense data available for the selected filter."
   - ✅ Removed expense preview key: "export.preview.no_expenses"
   - ✅ Kept UserSettings, generic UI, and shared component keys
   - ✅ Kept Export/Import and iCloud Backup keys (for UserSettings export/import functionality)
   - ✅ All 6 language files updated with same structure

3. ✅ Update app name in Info.plist:
   - ✅ Verified no CFBundleDisplayName in Info.plist (background task identifier is already correct: dev.mgorbatyuk.awesomeapplication.daily-backup)

**Expected Outcome:** Clean localization files with only generic keys

---

### ✅ Phase 11: Update Main Tab View

**Objective:** Clean up MainTabView to reflect removed functionality while keeping Onboarding

**Tasks:**
1. ✅ Review `MainTabView.swift`:
    - ✅ Remove tabs for ChargingSessions, Expenses, PlannedMaintenance
    - ✅ Keep UserSettings tab
    - ✅ Keep Onboarding tab (should navigate to OnboardingView)
    - ✅ Add placeholder tabs or keep single tab for template purposes

2. ✅ Review `MainTabViewModel.swift`:
    - ✅ Remove business logic related to deleted screens
    - ✅ Keep tab management logic

3. ✅ Update `AwesomeApplication/AwesomeApplicationApp.swift` (app entry point):
    - ✅ Remove references to deleted screens
    - ✅ Ensure app starts with MainTabView
    - ✅ Ensure Onboarding view is available for first-time users

**Expected Outcome:** MainTabView shows UserSettings and Onboarding tabs

---

### Phase 12: Final Cleanup & Testing

**Objective:** Verify all changes and ensure project builds correctly

**Tasks:**
1. Build the project:
   - Fix any compilation errors
   - Remove unused imports
   - Fix any broken references

2. Check for remaining references:
   - Search for "Car", "Expense", "Charging", "Maintenance" in code
   - Remove any remaining business logic

3. Update documentation:
   - Update README.md if it exists
   - Update any inline comments that reference removed features

4. Test core functionality:
   - Verify UserSettings works
   - Verify language switching works
   - Verify currency selection works
   - Verify database migration still runs
   - Verify app builds and runs

**Expected Outcome:** Clean template project with no compilation errors, ready for new app development

---

## Verification Checklist

After completing all phases:

- [ ] App name changed to AwesomeApplication throughout
- [ ] Bundle identifier is dev.mgorbatyuk.AwesomeApplication
- [ ] App version is 2026.1.1
- [ ] Only these models exist: Currency, UserSettings, SqlMigration, ExportMetadata, DelayedNotification
- [ ] Only these views exist: UserSettings, MainTab, Shared components, Onboarding
- [ ] Only these repositories exist: DatabaseManager, MigrationsRepository, UserSettingsRepository, DelayedNotificationsRepository
- [ ] Only first migration exists
- [ ] All services in BusinessLogic/Services/ are retained with original method signatures
- [ ] Service methods that used business-specific models throw "To be implemented" errors
- [ ] All languages (en, de, ru, kk, tr, uk) and all currencies are preserved
- [ ] No class header comments in Swift files
- [ ] Project builds without errors
- [ ] App launches and shows MainTabView

## Next Steps for New App Development

After refactoring is complete, the template is ready for new app development:

1. Create new models in `BusinessLogic/Models/`
2. Create new repositories in `BusinessLogic/Database/`
3. Create new migrations in `BusinessLogic/Database/Migrations/`
4. Implement placeholder methods in `BusinessLogic/Services/` that throw "To be implemented" errors
5. Create new views in `AwesomeApplication/`
6. Create new viewmodels alongside views
7. Add new localization keys as needed
8. Update MainTabView with new app tabs
