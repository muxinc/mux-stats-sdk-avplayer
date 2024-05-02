#!/bin/bash
set -euo pipefail

echo "▸ Current Xcode: $(xcode-select --print-path)"

echo "▸ Using Xcode Version: $(xcodebuild -version | grep Xcode | cut -d " " -f2)"

echo "▸ Set US UTF-8 Locale"
export LC_ALL=en_US.UTF-8

echo "▸ Validating Podspec"

pod lib lint --allow-warnings --verbose
