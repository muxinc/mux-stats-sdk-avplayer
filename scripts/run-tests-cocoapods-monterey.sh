#!/bin/bash
set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly WORKSPACE=DemoApp.xcworkspace
readonly SCHEME=DemoApp

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

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

cd apps/DemoApp

echo "▸ Reset Local Cocoapod Cache"
pod cache clean --all

echo "▸ Remove Podfile.lock"
rm -rf Podfile.lock

echo "▸ Reset Cocoapod Installation"
pod deintegrate && pod install --clean-install --repo-update

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list

echo "▸ Running ${SCHEME} Tests"
xcodebuild clean test \
    -workspace $WORKSPACE \
    -scheme $SCHEME \
    -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.5' | xcbeautify

