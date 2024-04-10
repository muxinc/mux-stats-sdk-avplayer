#!/bin/bash
set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
  echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

readonly PROJECT=MUXSDKStats.xcodeproj
readonly SCHEME=MUXSDKStats

cd MUXSDKStats

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 17.2 - iPhone 14 Pro Max"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=17.2,name=iPhone 14 Pro Max' \
  | xcbeautify

echo "▸ Testing SDK on iOS 17.2 - iPad Pro (12.9-inch) (6th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=17.2,name=iPad Pro (12.9-inch) (6th generation)' \
  | xcbeautify
