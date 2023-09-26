#!/bin/bash
set -euo pipefail

echo "▸ Use Xcode 14.2"

sudo xcode-select -switch /Applications/Xcode_14.2.app

echo "▸ Current Xcode: $(xcode-select --print-path)"

echo "▸ Using Xcode Version: $(xcodebuild -version | grep Xcode | cut -d " " -f2)"

echo "▸ Validating Podspec"

pod lib lint --allow-warnings --verbose

echo "▸ Back to Xcode 14.3.1"

sudo xcode-select -switch /Applications/Xcode_14.3.1.app/Contents/Developer
