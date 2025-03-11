#!/bin/bash
set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly PROJECT=MUXSDKStatsExampleSPM.xcodeproj
readonly SCHEME=MUXSDKStatsExampleSPM

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

cd apps/MUXSDKStatsExampleSPM

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Running ${SCHEME} Test when installed using Swift Package Manager"
echo ""

echo "▸ Testing SDK on iOS Simulator - iPhone 16 Pro"

xcodebuild clean build-for-testing \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -disableAutomaticPackageResolution \
    | xcbeautify

if [ "${1:-}" == 'build-only' ]; then
    exit 0
fi

xcodebuild test-without-building \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    | xcbeautify
