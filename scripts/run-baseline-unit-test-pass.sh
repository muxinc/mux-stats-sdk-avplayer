#!/bin/bash
set -euo pipefail

readonly PROJECT=MUXSDKStats.xcodeproj
readonly SCHEME=MUXSDKStats

cd MUXSDKStats

sudo xcode-select -s /Applications/Xcode_14.3.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.4 - iPhone 14 Pro Max"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.4,name=iPhone 14 Pro Max' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.4 - iPad Pro (12.9-inch) (6th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.4,name=iPad Pro (12.9-inch) (6th generation)' \
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
