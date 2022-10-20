#!/bin/bash
set -euo pipefail

brew install xcbeautify

# Delete the old stuff
rm -Rf XCFramework
# reset simulators
xcrun -v simctl shutdown all
xcrun -v simctl erase all

# Fetch artifact if running via buildkite (GitHub Actions fetches the artifact in a prior step)
#if command -v buildkite-agent > /dev/null 2>&1;
#then
#    buildkite-agent artifact download "MUXSDKStats.xcframework.zip" . --step ".github/workflows/scripts/build.sh"
#fi

unzip MUXSDKStats.xcframework.zip

cd apps/DemoApp
pod deintegrate && pod update

xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'id=53C7091D-5C64-4101-BF87-F40A2BDBA390' \
           test \
           | xcbeautify
