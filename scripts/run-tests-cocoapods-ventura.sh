#!/bin/bash
set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly WORKSPACE=DemoApp.xcworkspace
readonly SCHEME=DemoApp

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

echo "▸ Set US UTF-8 Locale"
export LC_ALL=en_US.UTF-8

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

cd apps/DemoApp

echo "▸ Reset Local Cocoapod Cache"
pod cache clean --all

echo "▸ Cocoapod Installation"
pod install --clean-install --repo-update --verbose

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list

echo "▸ Building tests for iOS Simulator"
xcodebuild clean build-for-testing \
    -workspace $WORKSPACE \
    -scheme $SCHEME \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    | xcbeautify

if [ "${1:-}" == 'build-only' ]; then
    exit 0
fi

echo "▸ Testing SDK on iOS Simulator - iPhone 16 Pro"
xcodebuild test-without-building \
    -workspace $WORKSPACE \
    -scheme $SCHEME \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    | xcbeautify
