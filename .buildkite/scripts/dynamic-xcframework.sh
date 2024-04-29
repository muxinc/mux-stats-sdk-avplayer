#!/bin/bash
set -euo pipefail

./scripts/create-dynamic-xcframework.sh
cd XCFramework
zip -ry MUXSDKStats.xcframework.zip MUXSDKStats.xcframework
