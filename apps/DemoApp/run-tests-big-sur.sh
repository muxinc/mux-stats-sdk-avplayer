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

echo "========= test xcode version"
xcodebuild -version

unzip MUXSDKStats.xcframework.zip
cd apps/DemoApp
pod deintegrate && pod update
xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'id=367F9736-5C05-4524-B7DA-6AB5245D0044' \
           test
