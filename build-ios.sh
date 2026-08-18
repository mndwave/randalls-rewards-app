#!/bin/zsh
set -e
source ~/.zshrc 2>/dev/null || true
cd ~/randalls-rewards-app/ios/App
echo "=== ARCHIVE START $(date) ==="
rm -rf build
xcodebuild \
  -project App.xcodeproj \
  -scheme App \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/App.xcarchive \
  clean archive \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=RH845KUW68
echo "=== ARCHIVE DONE $(date) ==="
xcodebuild \
  -exportArchive \
  -archivePath build/App.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates
echo "=== EXPORT DONE $(date) ==="
ls -la build/export
echo "BUILD_SCRIPT_COMPLETE_OK"
