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

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

echo "▸ Unzipping downloaded xcframework bundle"
unzip -o "XCFramework/MUXSDKStats.xcframework.zip"

cd apps/MUXSDKStatsExampleSPM

echo "▸ Resolving package dependencies"
xcodebuild -resolvePackageDependencies \
           -project MUXSDKStatsExampleSPM.xcodeproj | xcbeautify

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Running ${SCHEME} Test when installed using Swift Package Manager"
echo ""

echo "▸ Testing SDK on iOS 17.4 - iPhone 14 Pro Max"

xcodebuild clean test \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM" \
    -destination 'platform=iOS Simulator,OS=17.4,name=iPhone 15 Pro Max' | xcbeautify
