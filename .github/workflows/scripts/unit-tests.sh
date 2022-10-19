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
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro,OS=15.5' 
