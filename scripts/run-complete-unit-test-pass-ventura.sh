#!/bin/bash
set -euo pipefail

readonly PROJECT=MUXSDKStats.xcworkspace
readonly SCHEME=MUXSDKStats
readonly SCHEME_TVOS=MUXSDKStatsTv

cd MUXSDKStats

echo "▸ Reset Local Cocoapod Cache"
pod cache clean --all

echo "▸ Remove Podfile.lock"
rm -rf Podfile.lock

echo "▸ Reset Cocoapod Installation"
pod deintegrate && pod install --clean-install --repo-update

sudo xcode-select -s /Applications/Xcode_14.3.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.4 - iPhone 14 Pro Max"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.4,name=iPhone 14 Pro Max' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.4 - iPad Pro (12.9-inch) (6th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.4,name=iPad Pro (12.9-inch) (6th generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.4 - Apple TV"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.4,name=Apple TV' \
  -verbose \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.4 - Apple TV 4K (3rd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.4,name=Apple TV 4K (3rd generation)' \
  -verbose \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.4 - Apple TV 4K (3rd generation) (at 1080p)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.4,name=Apple TV 4K (3rd generation) (at 1080p)' \
  | xcbeautify

sudo xcode-select -s /Applications/Xcode_14.2.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.2 - iPhone 14"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone 14' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.2 - iPad Pro (11-inch) (4th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPad Pro (11-inch) (4th generation)' \
  | xcbeautify


echo "▸ Testing SDK on tvOS 16.1 - Apple TV"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.1,name=Apple TV' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.1 - Apple TV 4K (3rd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.1,name=Apple TV 4K (3rd generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.1 - Apple TV 4K (3rd generation) (at 1080p)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.1,name=Apple TV 4K (3rd generation) (at 1080p)' \
  | xcbeautify

sudo xcode-select -s /Applications/Xcode_14.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.1 - iPhone 14 Pro"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.1,name=iPhone 14 Pro' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.1 - iPad mini (6th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.1,name=iPad mini (6th generation)' \
  | xcbeautify


