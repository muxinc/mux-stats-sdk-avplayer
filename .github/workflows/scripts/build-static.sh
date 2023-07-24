#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod cache clean --all
pod repo update
pod deintegrate && pod install --repo-update
cd ..
./update-release-xcframeworks-static.sh
zip -ry MUXSDKStats-static.xcframework.zip XCFramework
