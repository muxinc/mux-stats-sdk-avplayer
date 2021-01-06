#!/bin/bash
set -euo pipefail

# Delete the old stuff
rm -Rf Frameworks

buildkite-agent artifact download "MUXSDKStats.xcframework.zip" . --step ".buildkite/build.sh"
unzip MUXSDKStats.xcframework.zip
cd apps/TestApp
pod deintegrate && pod install
xcodebuild -workspace TestApp.xcworkspace \
           -scheme "TestApp" \
           -destination 'platform=iOS Simulator,name=iPhone 11,OS=14.1' \
           test
