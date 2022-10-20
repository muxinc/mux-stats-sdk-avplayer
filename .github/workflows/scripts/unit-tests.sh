#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod repo update
pod deintegrate && pod install
cd ..
PROJECT=MUXSDKStats/MUXSDKStats.xcworkspace

xcodebuild clean test \
  -workspace $PROJECT \
  -scheme MUXSDKStats \
  -destination 'platform=iOS Simulator,OS=16.0,name=iPhone 14 Pro Max'
