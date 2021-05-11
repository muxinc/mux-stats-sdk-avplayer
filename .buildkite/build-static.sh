#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod repo update
pod deintegrate && pod install
cd ..
./update-release-xcframeworks-static.sh
zip -ry MUXSDKStats.xcframework.zip XCFramework
