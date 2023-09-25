#!/bin/bash
set -euo pipefail

# Delete the old stuff
rm -Rf XCFramework
# reset simulators
xcrun -v simctl shutdown all
xcrun -v simctl erase all

echo "test xcode version"
xcodebuild -version

unzip MUXSDKStats.xcframework.zip

cd apps/DemoApp

echo "▸ Reset Local Cocoapod Cache"
pod cache clean --all

echo "▸ Remove Podfile.lock"
rm -rf Podfile.lock

echo "▸ Reset Cocoapod Installation"
pod deintegrate && pod install --clean-install --repo-update

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list

echo "▸ Running Demo App Tests"
xcodebuild clean test \
    -workspace DemoApp.xcworkspace \
    -scheme "DemoApp" \
    -destination 'platform=iOS Simulator,OS=16.4,name=iPhone 14 Pro Max' | xcbeautify
