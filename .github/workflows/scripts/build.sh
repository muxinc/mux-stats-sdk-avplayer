#!/bin/bash
set -euo pipefail

./scripts/create-dynamic-xcframework.sh
zip -ry MUXSDKStats.xcframework.zip XCFramework
