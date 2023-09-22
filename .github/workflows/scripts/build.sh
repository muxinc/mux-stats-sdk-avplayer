#!/bin/bash
set -euo pipefail

./update-release-xcframeworks.sh
zip -ry MUXSDKStats.xcframework.zip XCFramework
