#!/bin/bash
set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
  echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

readonly SCHEME=MUXSDKStats

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 18.2 - iPhone 16 Pro"

xcodebuild clean test \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=18.2,name=iPhone 16 Pro' \
  | xcbeautify

echo "▸ Testing SDK on iOS 18.2 - iPad Pro 13-inch (M4)"

xcodebuild clean test \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=18.2,name=iPad Pro 13-inch (M4)' \
  | xcbeautify
