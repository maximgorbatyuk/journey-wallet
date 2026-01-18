#!/bin/sh
# ci_scripts/ci_post_clone.sh
# This script runs after Xcode Cloud clones your repository
#
# Required Environment Variables (set in Xcode Cloud):
#   - FIREBASE_API_KEY
#   - FIREBASE_GCM_SENDER_ID
#   - FIREBASE_APP_ID
#
# To set these in Xcode Cloud:
#   1. Go to App Store Connect > Xcode Cloud > Your Workflow
#   2. Click "Environment" tab
#   3. Add each variable as a "Secret" (not "Variable")

set -e

echo "🔧 Generating GoogleService-Info.plist from Xcode Cloud environment variables..."

# Verify required environment variables
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_GCM_SENDER_ID" ] || [ -z "$FIREBASE_APP_ID" ]; then
    echo "❌ Error: Required Firebase environment variables not set in Xcode Cloud"
    echo ""
    echo "Required secrets:"
    echo "  - FIREBASE_API_KEY"
    echo "  - FIREBASE_GCM_SENDER_ID"
    echo "  - FIREBASE_APP_ID"
    echo ""
    echo "Set these in: App Store Connect > Xcode Cloud > Workflow > Environment"
    exit 1
fi

# Define the path where the plist should be created
PLIST_PATH="$CI_PRIMARY_REPOSITORY_PATH/JourneyWallet/GoogleService-Info.plist"

# Create the GoogleService-Info.plist file
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>$FIREBASE_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>$FIREBASE_GCM_SENDER_ID</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>dev.mgorbatyuk.JourneyWallet</string>
    <key>PROJECT_ID</key>
    <string>journey-wallet-ce323</string>
    <key>STORAGE_BUCKET</key>
    <string>journey-wallet-ce323.firebasestorage.app</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <true/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>$FIREBASE_APP_ID</string>
</dict>
</plist>
EOF

# Verify the file was created (don't print contents - they contain secrets)
if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully"
    echo "   Path: $PLIST_PATH"
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi
