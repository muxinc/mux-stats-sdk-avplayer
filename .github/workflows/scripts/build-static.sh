#!/bin/bash
set -euo pipefail

./create-static-xcframework.sh
zip -ry MUXSDKStats-static.xcframework.zip XCFramework
