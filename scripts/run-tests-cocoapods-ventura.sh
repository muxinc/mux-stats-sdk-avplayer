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

echo "▸ Set US UTF-8 Locale"
export LC_ALL=en_US.UTF-8

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

echo "▸ Unzipping downloaded xcframework bundle"
unzip -o "XCFramework/MUXSDKStats.xcframework.zip"

cd apps/DemoApp

echo "▸ Reset Local Cocoapod Cache"
pod cache clean --all

echo "▸ Remove Podfile.lock"
rm -rf Podfile.lock

echo "▸ Reset Cocoapod Installation"
pod deintegrate && pod install --clean-install --repo-update --verbose

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list

echo "▸ Testing SDK on iOS 17.5 - iPhone 15 Pro Max"
xcodebuild clean test \
    -workspace $WORKSPACE \
    -scheme $SCHEME \
    -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro Max' | xcbeautify
