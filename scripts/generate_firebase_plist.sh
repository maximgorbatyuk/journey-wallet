#!/bin/bash
# Generate GoogleService-Info.plist from environment variables
# This script is for LOCAL development and testing only
# For Xcode Cloud, secrets are stored in Xcode Cloud environment variables

set -e

echo "🔥 Generating GoogleService-Info.plist..."
echo ""

# Check for .env file
ENV_FILE="./scripts/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: scripts/.env file not found!"
    echo ""
    echo "Create scripts/.env file with the following content:"
    echo ""
    echo "  export FIREBASE_API_KEY=\"your-api-key\""
    echo "  export FIREBASE_GCM_SENDER_ID=\"your-sender-id\""
    echo "  export FIREBASE_APP_ID=\"your-app-id\""
    echo ""
    echo "Get these values from Firebase Console:"
    echo "  https://console.firebase.google.com > Project Settings > Your iOS app"
    exit 1
fi

# Source environment variables
source "$ENV_FILE"

# Verify required variables
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_GCM_SENDER_ID" ] || [ -z "$FIREBASE_APP_ID" ]; then
    echo "❌ Error: Required Firebase environment variables not set"
    echo ""
    echo "Required variables in scripts/.env:"
    echo "  - FIREBASE_API_KEY"
    echo "  - FIREBASE_GCM_SENDER_ID"
    echo "  - FIREBASE_APP_ID"
    exit 1
fi

# Generate the plist
PLIST_PATH="./JourneyWallet/GoogleService-Info.plist"

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

if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully!"
    echo "   Path: $PLIST_PATH"
    echo ""
    echo "⚠️  Remember: This file is git-ignored and should NOT be committed."
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi
