#!/bin/bash
echo "======"
pwd
ls -lisa
ls -lisa ..
ls -lisa ../..
echo "======"

set -euo pipefail

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
           -destination 'platform=iOS Simulator,name=iPhone 11,OS=14.1' \
           test
