#!/bin/bash
set -euo pipefail

echo "▸ Current Xcode: $(xcode-select --print-path)"

echo "▸ Using Xcode Version: $(xcodebuild -version | grep Xcode | cut -d " " -f2)"

echo "▸ Validating Podspec"

pod lib lint --allow-warnings --verbose

echo "▸ Back to Xcode 14.3.1"
