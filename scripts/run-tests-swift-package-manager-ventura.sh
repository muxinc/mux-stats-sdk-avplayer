#!/bin/bash
set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly PROJECT=MUXSDKStatsExampleSPM.xcodeproj
readonly PACKAGE_RESOLVED_FILE="$PWD/Examples/MUXSDKStatsExampleSPM/MUXSDKStatsExampleSPM.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
readonly SCHEME=MUXSDKStatsExampleSPM

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"

function resolve_packages {
    echo "--- Resolving package dependencies"

    xcodebuild -resolvePackageDependencies -project "MUXSDKStatsExampleSPM.xcodeproj"

    cp -ac "$PACKAGE_RESOLVED_FILE" "$ARTIFACTS_DIR"
}

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

cd Examples/MUXSDKStatsExampleSPM

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Running ${SCHEME} Test when installed using Swift Package Manager"
echo ""

echo "▸ Testing SDK on iOS Simulator - iPhone 16 Pro"

resolve_packages

xcodebuild clean build-for-testing \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -allowProvisioningUpdates \
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
