#!/bin/bash
set -euo pipefail

./update-release-xcframeworks-static.sh
zip -ry MUXSDKStats-static.xcframework.zip XCFramework
