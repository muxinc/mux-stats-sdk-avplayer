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

sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer

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

echo "▸ Testing SDK on tvOS 17.2 - Apple TV"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=17.2,name=Apple TV' \
  -verbose \
  | xcbeautify

echo "▸ Testing SDK on tvOS 17.2 - Apple TV 4K (3rd generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=17.2,name=Apple TV 4K (3rd generation)' \
  -verbose \
  | xcbeautify

echo "▸ Testing SDK on tvOS 17.2 - Apple TV 4K (3rd generation) (at 1080p)"

sudo xcode-select -s /Applications/Xcode_14.3.1.app/Contents/Developer

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=17.2,name=Apple TV 4K (3rd generation) (at 1080p)' \
  | xcbeautify

sudo xcode-select -s /Applications/Xcode_14.2.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.2 - iPhone 14"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone 14' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.2 - iPad Pro (11-inch) (4th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPad Pro (11-inch) (4th generation)' \
  | xcbeautify


echo "▸ Testing SDK on tvOS 16.1 - Apple TV"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.1,name=Apple TV' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.1 - Apple TV 4K (3rd generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.1,name=Apple TV 4K (3rd generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.1 - Apple TV 4K (3rd generation) (at 1080p)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.1,name=Apple TV 4K (3rd generation) (at 1080p)' \
  | xcbeautify

sudo xcode-select -s /Applications/Xcode_14.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.1 - iPhone 14 Pro"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.1,name=iPhone 14 Pro' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.1 - iPad mini (6th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.1,name=iPad mini (6th generation)' \
  | xcbeautify


