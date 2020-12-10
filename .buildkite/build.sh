#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod repo update
pod deintegrate && pod install
cd ..
./update-release-xcframeworks.sh
zip -r MUXSDKStats.xcframework.zip XCFramework
