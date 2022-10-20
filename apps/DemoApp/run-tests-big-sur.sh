#!/bin/bash
set -euo pipefail

brew install xcbeautify

# Delete the old stuff
rm -Rf XCFramework
# reset simulators
xcrun -v simctl shutdown all
xcrun -v simctl erase all

# Fetch artifact if running via buildkite (GitHub Actions fetches the artifact in a prior step)
if command -v buildkite-agent > /dev/null 2>&1;
then
    buildkite-agent artifact download "MUXSDKStats.xcframework.zip" . --step ".buildkite/build.sh"
fi

unzip MUXSDKStats.xcframework.zip
cd apps/DemoApp
pod deintegrate && pod update
xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'id=7EDC75D2-89BC-4138-88C2-F5538F273DFF' \
           test
