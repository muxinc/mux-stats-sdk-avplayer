#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod repo update
pod deintegrate && pod install
cd ..
./update-release-xcframeworks.sh
./update-release-xcframeworks-static.sh
zip -ry MUXSDKStats.xcframework.zip XCFramework
zip -ry MUXSDKStats-static.xcframework.zip XCFramework/static
