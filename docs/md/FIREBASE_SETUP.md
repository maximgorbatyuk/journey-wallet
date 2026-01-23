# Firebase & iCloud Setup for Journey Wallet

This guide explains the manual steps required to configure Firebase and iCloud for the Journey Wallet iOS app.

## Firebase Configuration

### Step 1: Create or Update Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Sign in with your Google account
3. Click "Add project" or select existing project

**If creating a new project:**
- Project name: `journey-wallet-firebase`
- Google Analytics: Enable (recommended)
- Create the project

### Step 2: Add iOS App to Firebase Project

1. In Firebase Console, go to Project Settings → Your apps
2. Click "Add app" → iOS icon
3. Fill in the following details:
   - **iOS Bundle ID**: `dev.mgorbatyuk.JourneyWallet`
   - **App nickname**: `Journey Wallet`
   - **App Store ID**: (leave blank if not in App Store yet)
   - Click "Register app"

### Step 3: Download GoogleService-Info.plist

1. After registering the app, download `GoogleService-Info.plist`
2. Place it in: `JourneyWallet/GoogleService-Info.plist`
3. **Important**: Add this file to `.gitignore` to avoid committing sensitive Firebase credentials

### Step 4: Configure Firebase for Different Environments

**For Local Development:**
- The downloaded `GoogleService-Info.plist` will be used
- Ensure file is added to Xcode project target
- Build and test the app locally

**For CI/CD (Xcode Cloud):**
- The `ci_scripts/ci_post_clone.sh` script will auto-generate the file
- Set these environment variables in App Store Connect:
  - `FIREBASE_API_KEY`
  - `FIREBASE_GCM_SENDER_ID`
  - `FIREBASE_APP_ID`

**For Local Development with .env:**
1. Create `scripts/.env` file (already in `.gitignore`)
2. Add the following content:
```bash
export FIREBASE_API_KEY="your-api-key-here"
export FIREBASE_GCM_SENDER_ID="your-sender-id-here"
export FIREBASE_APP_ID="your-app-id-here"
```
3. Source the file before building:
```bash
source scripts/.env
./scripts/build_and_distribute.sh
```

### Firebase Project Details

After setup, your Firebase project should have:
- **Project ID**: `journey-wallet-firebase`
- **Storage Bucket**: `journey-wallet-firebase.firebasestorage.app`
- **iOS Bundle ID**: `dev.mgorbatyuk.JourneyWallet`

## iCloud Configuration

### Step 1: Create iCloud Container in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to: Identifiers → iCloud Containers
3. Click "+" to create a new container
4. Enter Container ID: `iCloud.com.journeywallet.JourneyWallet`
5. Click "Continue" and then "Register"

### Step 2: Update App Identifier with iCloud Container

1. In Apple Developer Portal, go to: Identifiers → App IDs
2. Find your app identifier: `dev.mgorbatyuk.JourneyWallet`
3. Edit the identifier
4. Under "iCloud" section, click "Edit"
5. Add the container: `iCloud.com.journeywallet.JourneyWallet`
6. Save changes

### Step 3: Update Provisioning Profiles

After updating the App ID:
1. Update all provisioning profiles (Development and Distribution)
2. Download the updated profiles
3. Install them on your development machine
4. In Xcode, select the updated profile in Signing & Capabilities

### Step 4: Verify Entitlements File

The `JourneyWallet/JourneyWallet.entitlements` file should contain:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
  <string>iCloud.com.journeywallet.JourneyWallet</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
  <string>CloudDocuments</string>
</array>
<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
  <string>iCloud.com.journeywallet.JourneyWallet</string>
</array>
```

This file has already been updated in Phase 3 of the refactoring.

## Testing iCloud Sync

### Testing on Simulator

1. Build and run the app on iOS Simulator
2. Enable iCloud in app settings
3. Add some test data (expenses)
4. Verify the data is synced to iCloud (may need to check in iCloud Drive)

### Testing on Device

1. Build and run on a physical iOS device
2. Enable iCloud in app settings
3. Add test data on Device A
4. Install the app on Device B (signed with same Apple ID)
5. Sign in to the same iCloud account on both devices
6. Verify data syncs between devices

## Troubleshooting

### Firebase Issues

**"GoogleService-Info.plist not found"**
- Ensure the file is in the correct location: `JourneyWallet/GoogleService-Info.plist`
- Check that the file is added to the Xcode project target
- Verify it's not gitignored (unless using CI/CD)

**"Firebase project not found"**
- Verify PROJECT_ID in `GoogleService-Info.plist` matches your Firebase console
- Check that the bundle ID matches exactly: `dev.mgorbatyuk.JourneyWallet`

### iCloud Issues

**"iCloud container not found"**
- Verify container ID matches in Apple Developer Portal and entitlements file
- Ensure App ID has the iCloud capability enabled
- Check that provisioning profiles are up to date

**"Data not syncing"**
- Ensure both devices are signed in to the same iCloud account
- Verify iCloud Drive is enabled on both devices
- Check that the app has iCloud permissions in Settings → [Your Name] → iCloud
- Test with stable internet connection

## Summary of Completed Changes

The following have been completed in the refactoring:

### Code Changes (Automated)
- ✅ Updated `JourneyWallet/JourneyWallet.entitlements` with new iCloud container IDs
- ✅ Updated all Firebase references in CI scripts to use new project ID
- ✅ Updated `JourneyWallet/Info.plist` with new BGTaskScheduler identifiers

### Manual Steps Required (Your Action)
- [ ] Create Firebase project or update existing
- [ ] Register iOS app in Firebase with bundle ID `dev.mgorbatyuk.JourneyWallet`
- [ ] Download and place `GoogleService-Info.plist`
- [ ] Create iCloud container: `iCloud.com.journeywallet.JourneyWallet`
- [ ] Update App ID with iCloud container capability
- [ ] Update provisioning profiles
- [ ] Test iCloud sync functionality

## Next Steps

After completing the manual steps above:

1. **Build and Test** locally
2. **Run Tests**: `./run_tests.sh`
3. **Commit Changes**: Add `GoogleService-Info.plist` to `.gitignore` if desired
4. **Deploy**: Use `./scripts/build_and_distribute.sh` for Xcode Cloud deployment

## References

- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [Apple iCloud Documentation](https://developer.apple.com/documentation/cloudkit/)
