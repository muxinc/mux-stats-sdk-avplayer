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
  -destination 'platform:iOS Simulator, OS:14.4, name:iPhone 12 Pro Max' 
