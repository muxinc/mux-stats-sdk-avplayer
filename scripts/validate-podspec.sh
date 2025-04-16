#!/bin/bash
set -euo pipefail

echo "▸ Current Xcode: $(xcode-select --print-path)"

echo "▸ Using Xcode Version: $(xcodebuild -version | grep Xcode | cut -d " " -f2)"

echo "▸ Set US UTF-8 Locale"
export LC_ALL=en_US.UTF-8

echo "--- Linting Podspec (default options)"
pod lib lint --skip-tests

echo "--- Linting Podspec (using libraries)"
pod lib lint --skip-tests --use-libraries

echo "--- Linting Podspec (using libraries and modular headers)"
pod lib lint --skip-tests --use-libraries --use-modular-headers

echo "--- Linting Podspec (using static frameworks)"
pod lib lint --skip-tests --use-static-frameworks
