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
pod deintegrate && pod update
xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.5' \
           test \
           | xcbeautify

