#!/bin/bash
set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
	echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)

cd apps/MUXSDKStatsExampleSPM

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Resolving SPM Dependencies"

xcodebuild -resolvePackageDependencies \
		   -project MUXSDKStatsExampleSPM.xcodeproj | xcbeautify

echo "▸ Running Swift Package Manager Tests"
echo ""
echo "▸ Testing SDK on iOS 17.0.1 - iPhone 15 Pro Max"

xcodebuild clean test \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM" \
    -destination 'platform=iOS Simulator,OS=17.0.1,name=iPhone 15 Pro Max' | xcbeautify

echo "▸ Testing Mac Catalyst - Designed for iPad variant"

xcodebuild clean test \
	-project MUXSDKStatsExampleSPM.xcodeproj \
	-scheme "MUXSDKStatsExampleSPM" \
	-destination 'generic/platform=macOS,arch=arm64,variant=Designed for iPad' | xcbeautify
