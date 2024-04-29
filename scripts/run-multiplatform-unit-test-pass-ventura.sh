#!/bin/bash
set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
  echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

readonly PROJECT=MUXSDKStats.xcodeproj
readonly SCHEME=MUXSDKStats
readonly SCHEME_TVOS=MUXSDKStatsTv

cd MUXSDKStats

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 17.4 - iPhone 14 Pro Max"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=17.4,name=iPhone 14 Pro Max' \
  | xcbeautify

echo "▸ Testing SDK on iOS 17.4 - iPad Pro (12.9-inch) (6th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=17.4,name=iPad Pro (12.9-inch) (6th generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 17.4 - Apple TV"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=17.4,name=Apple TV' \
  -verbose \
  | xcbeautify

echo "▸ Testing SDK on tvOS 17.4 - Apple TV 4K (3rd generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=17.4,name=Apple TV 4K (3rd generation)' \
  -verbose \
  | xcbeautify
  
