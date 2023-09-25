#!/bin/bash
set -euo pipefail

./create-dynamic-xcframework.sh
zip -ry MUXSDKStats.xcframework.zip XCFramework
