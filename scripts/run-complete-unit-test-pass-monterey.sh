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

sudo xcode-select -s /Applications/Xcode_14.0.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 16.0 - iPhone 14 Pro Max"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPhone 14 Pro Max' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.0 - iPhone 11"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPhone 11' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.0 - iPad Air (4th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPad Air (4th generation)' \
  | xcbeautify

echo "▸ Testing SDK on iOS 16.0 - iPad mini (6th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPad mini (6th generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.0 - Apple TV"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.0,name=Apple TV' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.0 - Apple TV 4K (2nd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.0,name=Apple TV 4K (2nd generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 16.0 - Apple TV 4K (3rd generation) (at 1080p)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=16.0,name=Apple TV 4K (3rd generation) (at 1080p)' \
  | xcbeautify

sudo xcode-select -s /Applications/Xcode_13.4.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 15.5 - iPhone 13"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=15.5,name=iPhone 13' \
  | xcbeautify

echo "▸ Testing SDK on iOS 15.5 - iPhone 12 mini"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=15.5,name=iPhone 12 mini' \
  | xcbeautify

echo "▸ Testing SDK on iOS 15.5 - iPad (9th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=15.5,name=iPad (9th generation)' \
  | xcbeautify

echo "▸ Testing SDK on iOS 15.5 - iPad mini (6th generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=15.5,name=iPad mini (6th generation)' \
  | xcbeautify


echo "▸ Testing SDK on tvOS 15.4 - Apple TV"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=15.4,name=Apple TV' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 15.4 - Apple TV 4K (2nd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=15.4,name=Apple TV 4K (2nd generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 15.4 - Apple TV 4K (at 1080p) (2nd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=15.4,name=Apple TV 4K (at 1080p) (2nd generation)' \
  | xcbeautify

sudo xcode-select -s /Applications/Xcode_13.1.app/

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Available Xcode SDKs"

xcodebuild -showsdks

echo "▸ Testing SDK on iOS 15.0 - iPhone 12 mini"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=15.0,name=iPhone 12 mini' \
  | xcbeautify

echo "▸ Testing SDK on iOS 15.0 - iPad Pro (9.7-inch)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME \
  -destination 'platform=iOS Simulator,OS=15.0,name=iPad Pro (9.7-inch)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 15.0 - Apple TV"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=15.0,name=Apple TV' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 15.0 - Apple TV 4K (2nd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=15.0,name=Apple TV 4K (2nd generation)' \
  | xcbeautify

echo "▸ Testing SDK on tvOS 15.0 - Apple TV 4K (at 1080p) (2nd generation)"

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme $SCHEME_TVOS \
  -destination 'platform=tvOS Simulator,OS=15.0,name=Apple TV 4K (at 1080p) (2nd generation)' \
  | xcbeautify
