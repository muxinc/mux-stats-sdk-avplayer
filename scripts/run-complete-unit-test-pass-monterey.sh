#!/bin/bash
set -euo pipefail

readonly PROJECT=MUXSDKStats.xcodeproj
readonly SCHEME=MUXSDKStats
readonly SCHEME_TVOS=MUXSDKStatsTv

cd MUXSDKStats

sudo xcode-select -s /Applications/Xcode_14.0.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.0 - iPhone 14 Pro Max"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPhone 14 Pro Max' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.0 - iPhone 11"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPhone 11' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.0 - iPad Air (4th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPad Air (4th generation)' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.0 - iPad mini (6th generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPad mini (6th generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.0 - Apple TV"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.0,name=Apple TV' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.0 - Apple TV 4K (2nd generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.0,name=Apple TV 4K (2nd generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.0 - Apple TV 4K (at 1080p) (2nd generation)"

xcodebuild clean test \
  -project $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.0,name=Apple TV 4K (at 1080p) (2nd generation)' \
  | xcbeautify
