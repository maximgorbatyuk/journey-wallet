# Application Refactoring Plan

The goal of the refactoring is to convert existing app into Journey Wallet app.

## Current State Analysis

**Current naming inconsistencies found:**
- Project name: `AwesomeApplication`
- Main scheme: `AwesomeApplication.xcscheme`
- Active scheme (used in scripts): `EVChargingTracker.xcscheme` (no folder exists)
- Bundle identifiers:
  - dev.mgorbatyuk.AwesomeApplication (Release)
  - dev.mgorbatyuk.AwesomeApplicationDebug (Debug)
  - dev.mgorbatyuk.AwesomeApplicationTests (Tests)
- Entitlements: iCloud.com.awesomeapplication.AwesomeApplication
- BG task identifier: dev.mgorbatyuk.awesomeapplication.daily-backup
- Firebase references: dev.mgorbatyuk.EvChargeTracker, ev-charge-tracker-851bf
- CI/Scripts references: EVChargingTracker (non-existent folder)

## Goals

- [ ] Rename the app to "Journey Wallet" ("AwesomeApplication" -> "JourneyWallet")
- [ ] Change identifier of the app to "dev.mgorbatyuk.JourneyWallet" and use this everywhere instead of old one
- [ ] Rename the app target to "JourneyWallet"
- [ ] Remove or update conflicting EVChargingTracker references
- [ ] Clean up inconsistent scheme names

## Detailed Refactoring Plan

### Phase 1: Xcode Project Configuration Updates

#### 1.1 Project File Updates
- [ ] Open `AwesomeApplication.xcodeproj` in Xcode
- [ ] Rename project from "AwesomeApplication" to "JourneyWallet" in the Project Navigator
- [ ] Accept Xcode's prompt to rename project items
- [ ] Update project display name in Build Settings
- [ ] Update Product Name in Build Settings: "JourneyWallet"

#### 1.2 Target Configuration
- [ ] Select target in project settings
- [ ] General tab > Display Name: "Journey Wallet"
- [ ] General tab > Bundle Identifier: "dev.mgorbatyuk.JourneyWallet"
- [ ] Build Settings > Product Name: "JourneyWallet"

#### 1.3 Scheme Management
- [ ] In Xcode > Product > Scheme > Manage Schemes
- [ ] Delete old "EVChargingTracker.xcscheme" (if exists)
- [ ] Keep "JourneyWallet.xcscheme" as the only scheme
- [ ] Set "JourneyWallet" as default scheme (checked)
- [ ] Edit scheme > Run > Info > Build Configuration: Debug
- [ ] Edit scheme > Run > Info > Executable: JourneyWallet.app

#### 1.4 Build Configuration Updates
- [ ] Update Release configuration bundle identifier: dev.mgorbatyuk.JourneyWallet
- [ ] Update Debug configuration bundle identifier: dev.mgorbatyuk.JourneyWallet
- [ ] Update Tests bundle identifier: dev.mgorbatyuk.JourneyWalletTests

### Phase 2: File and Folder Renaming

#### 2.1 Directory Structure
- [ ] Close Xcode completely
- [ ] Rename folder in Finder: `AwesomeApplication` -> `JourneyWallet`
- [ ] Rename tests folder: `AwesomeApplicationTests` -> `JourneyWalletTests`
- [ ] Rename project file: `AwesomeApplication.xcodeproj` -> `JourneyWallet.xcodeproj`

#### 2.2 File References
- [ ] Rename `AwesomeApplication/Info.plist` -> `JourneyWallet/Info.plist`
- [ ] Rename `AwesomeApplication/AwesomeApplicationApp.swift` -> `JourneyWallet/JourneyWalletApp.swift`
- [ ] Rename `AwesomeApplication/AwesomeApplication.entitlements` -> `JourneyWallet/JourneyWallet.entitlements`

### Phase 3: Code Updates

#### 3.1 Main App File
- [ ] Update struct name in `JourneyWalletApp.swift`: `AwesomeApplicationApp` -> `JourneyWalletApp`
- [ ] Update `@main` attribute if needed
- [ ] Update any import statements referencing old module name

#### 3.2 Info.plist Updates
- [ ] Update BGTaskSchedulerPermittedIdentifiers array:
  - Change: `dev.mgorbatyuk.awesomeapplication.daily-backup`
  - To: `dev.mgorbatyuk.journeywallet.daily-backup`

#### 3.3 Entitlements File Updates
- [ ] Update iCloud container identifiers in `JourneyWallet.entitlements`:
  - Change: `iCloud.com.awesomeapplication.AwesomeApplication`
  - To: `iCloud.com.journeywallet.JourneyWallet` (or dev.mgorbatyuk.JourneyWallet)
- [ ] Update ubiquity container identifiers:
  - Change: `iCloud.com.awesomeapplication.AwesomeApplication`
  - To: `iCloud.com.journeywallet.JourneyWallet` (or dev.mgorbatyuk.JourneyWallet)

#### 3.4 Code References
- [ ] Search all Swift files for "AwesomeApplication" references and update
- [ ] Search all Swift files for "EVChargingTracker" references and update
- [ ] Update test files with new target name references

### Phase 4: Scripts and CI Updates

#### 4.1 Test Scripts
- [ ] Update `run_tests.sh`:
  - Change: `-scheme EVChargingTracker`
  - To: `-scheme JourneyWallet`

#### 4.2 CI Scripts
- [ ] Update `ci_scripts/ci_post_clone.sh`:
  - Change PLIST_PATH from `EVChargingTracker/GoogleService-Info.plist` to `JourneyWallet/GoogleService-Info.plist`
  - Change BUNDLE_ID from `dev.mgorbatyuk.EvChargeTracker` to `dev.mgorbatyuk.JourneyWallet`
  - Update Firebase project references (may need new Firebase project)
  - Update PROJECT_ID if creating new Firebase project
  - Update STORAGE_BUCKET if creating new Firebase project

#### 4.3 Other Scripts
- [ ] Update any scripts in `scripts/` directory
- [ ] Update `scripts/scripts.md` documentation
- [ ] Update any other shell scripts or makefiles

### Phase 5: Documentation Updates

#### 5.1 README and Documentation
- [x] Update `readme.md` with new app name
- [x] Update `refactoring.md` (this file) as items are completed
- [x] Update `appstore_page.md` if exists
- [x] Update any documentation in `docs/` directory

#### 5.2 Metadata
- [x] Update `privacy-policy.md` if app name is mentioned
- [x] Update `changelog.md` if needed

### Phase 6: Firebase/External Services

**NOTE:** External services (Firebase, iCloud) require manual configuration in their respective portals. Code changes are complete. See `FIREBASE_SETUP.md` for detailed instructions.

#### 6.1 Firebase Configuration
- [ ] Create new Firebase project for "Journey Wallet" or update existing
- [ ] Generate new GoogleService-Info.plist with:
  - Bundle ID: dev.mgorbatyuk.JourneyWallet
  - New PROJECT_ID for journeywallet (if creating new project)
  - New STORAGE_BUCKET (if creating new project)
- [x] Place new GoogleService-Info.plist in JourneyWallet/ directory (note: generated by CI scripts)
- [x] Update Firebase configuration in all environments (scripts already updated in Phase 4)

#### 6.2 iCloud Configuration
- [ ] Update iCloud container in Apple Developer Portal (create: iCloud.com.journeywallet.JourneyWallet)
- [x] Update entitlements with new container identifier (completed in Phase 3)
- [ ] Test iCloud sync functionality after update

**Resources:**
- See `FIREBASE_SETUP.md` for detailed setup instructions for Firebase and iCloud
- Firebase Console: https://console.firebase.google.com/
- Apple Developer Portal: https://developer.apple.com/account/

### Phase 7: Testing and Validation

#### 7.1 Build Validation
- [ ] Clean build folder: Product > Clean Build Folder
- [ ] Build for iOS Simulator: Command + B
- [ ] Build for iOS Device (if provisioning profile available)
- [ ] Fix any build errors related to naming

#### 7.2 Testing
- [ ] Run unit tests: Command + U
- [ ] Run UI tests if exist
- [ ] Run app on simulator to verify launch
- [ ] Test all background task functionality
- [ ] Test iCloud sync if applicable

#### 7.3 Scheme Validation
- [ ] Verify "JourneyWallet" scheme is listed
- [ ] Verify no old schemes remain
- [ ] Test running with Command + R
- [ ] Test profiling with Command + I

### Phase 8: Git Management

- [ ] Review all changes with `git status`
- [ ] Add renamed files: `git add -A`
- [ ] Commit with message: "Refactor: Rename app from AwesomeApplication to JourneyWallet"
- [ ] Verify no old references remain with: `git grep -i awesomeapplication`
- [ ] Verify no old references remain with: `git grep -i evchargingtracker`

## Notes and Considerations

1. **iCloud Data Migration**: If users have existing data in iCloud, consider migration strategy
2. **Provisioning Profiles**: May need to create new provisioning profiles with new bundle ID
3. **App Store Connect**: If app was previously published, this is a different app (new bundle ID)
4. **Firebase Analytics**: New app ID means analytics start from scratch
5. **Push Notifications**: May need to update APNs certificates
6. **Deep Links**: Update any universal links or custom URL schemes

## Post-Refactoring Checklist

- [ ] All build configurations successful
- [ ] All tests pass
- [ ] App launches and runs on simulator
- [ ] iCloud container properly configured
- [ ] Background tasks scheduled correctly
-- Firebase configuration valid
- [ ] CI/CD pipeline updated and working
- [ ] Documentation updated
- [ ] No references to old names in codebase
- [ ] No references to old names in scripts
- [ ] Git history properly preserved

All other features will be added later with separate tasks.
