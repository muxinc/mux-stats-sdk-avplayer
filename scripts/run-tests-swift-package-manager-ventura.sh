#!/bin/bash
set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly PROJECT=MUXSDKStatsExampleSPM.xcodeproj
readonly SCHEME=MUXSDKStatsExampleSPM

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

sh scripts/setup-local-hls-server.sh

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

echo "▸ Removing XCFramework folder"
rm -Rf XCFramework

echo "▸ Shutdown all simulators"
xcrun -v simctl shutdown all

echo "▸ Erase all simulators"
xcrun -v simctl erase all

echo "▸ Unzipping XCFramework"
unzip MUXSDKStats.xcframework.zip

cd apps/MUXSDKStatsExampleSPM

echo "▸ Resolving package dependencies"
xcodebuild -resolvePackageDependencies \
           -project MUXSDKStatsExampleSPM.xcodeproj | xcbeautify

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Running ${SCHEME} Test when installed using Swift Package Manager"
echo ""

echo "▸ Testing SDK on iOS 17.2 - iPhone 14 Pro Max"

xcodebuild clean test \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM-CI" \
    -destination 'platform=iOS Simulator,OS=17.2,name=iPhone 14 Pro Max' | xcbeautify
