#!/bin/bash
set -euo pipefail

./scripts/create-static-xcframework.sh
cd XCFramework
zip -ry MUXSDKStats-static.xcframework.zip MUXSDKStats.xcframework
