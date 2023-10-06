#!/bin/bash
set -euo pipefail

./scripts/create-static-xcframework.sh
zip -ry MUXSDKStats-static.xcframework.zip XCFramework
