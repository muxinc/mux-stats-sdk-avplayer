#!/bin/bash
set -euo pipefail

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"

readonly TEST_PRODUCTS_PATH="$ARTIFACTS_DIR/MUXSDKStats-iOS.xctestproducts"

rm -rf "$TEST_PRODUCTS_PATH"
unzip "$TEST_PRODUCTS_PATH.zip" -d  "$TEST_PRODUCTS_PATH" 

echo "Running Sauce Labs"
saucectl run