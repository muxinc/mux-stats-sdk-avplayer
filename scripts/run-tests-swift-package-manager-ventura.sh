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

echo "▸ Shutdown all simulators"
xcrun -v simctl shutdown all

echo "▸ Erase all simulators"
xcrun -v simctl erase all

cd apps/MUXSDKStatsExampleSPM

echo "▸ Resolving package dependencies"
xcodebuild -resolvePackageDependencies

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Running ${SCHEME} Tests"
xcodebuild clean test \
    -project $PROJECT \
    -scheme $SCHEME \
    -destination 'platform=iOS Simulator,OS=17.0.1,name=iPhone 15 Pro Max' | xcbeautify
