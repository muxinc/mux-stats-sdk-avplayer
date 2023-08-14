#!/bin/bash
set -euo pipefail

brew install xcbeautify

# Delete the old stuff
rm -Rf XCFramework
# reset simulators
xcrun -v simctl shutdown all
xcrun -v simctl erase all

echo "test xcode version"
xcodebuild -version

unzip MUXSDKStats.xcframework.zip

cd apps/DemoApp
pod deintegrate && pod update

xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'platform=iOS Simulator,OS=16.2,name=iPhone 14 Pro Max' \
           test \
           | xcbeautify

