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
  -destination 'platform:iOS Simulator, id:020403AC-9B29-406D-93A3-06980FBD6750, OS:14.4, name:iPhone 12 Pro Max' 
