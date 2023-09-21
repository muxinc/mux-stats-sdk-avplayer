#!/bin/bash
set -euo pipefail

brew install xcbeautify

echo "Running unit tests on Xcode version: $(xcode-select -p)"

# Delete the old stuff
rm -Rf XCFramework
# reset simulators
xcrun -v simctl shutdown all
xcrun -v simctl erase all

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
    -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.5' | xcbeautify

