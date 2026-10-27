#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

test_destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"
test_derived_data="${TEST_DERIVED_DATA:-.ui-test-cache/UnitDerivedData}"
test_results="build/UnitTests-$(date -u +%Y%m%dT%H%M%SZ).xcresult"
mkdir -p build

xcodebuild test \
  -project JourneyWallet.xcodeproj \
  -scheme JourneyWalletTests \
  -destination "$test_destination" \
  -derivedDataPath "$test_derived_data" \
  -clonedSourcePackagesDirPath .ui-test-cache/DerivedData/SourcePackages \
  -enableCodeCoverage YES \
  -resultBundlePath "$test_results"

python3 -m unittest discover -s scripts -p 'test_*.py' -v
python3 scripts/run_ui_scenario.py --scenario create-edit-cancel
python3 scripts/run_ui_scenario.py --scenario notes-links-documents
