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

echo "+++++"
ls -lisa 
ls -lisa XCFramework
echo "AND THE ARTIFACT ZIP"
zipinfo -l MUXSDKStats.xcframework.zip
echo "+++++"

cd apps/DemoApp
pod deintegrate && pod update

echo "======"
pwd
ls -lisa
ls -lisa ..
ls -lisa ../..
echo "======"

xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'platform=iOS Simulator,OS=16.0,name=iPhone 14 Pro Max' \
           test \
           | xcbeautify
