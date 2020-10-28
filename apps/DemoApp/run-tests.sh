#!/bin/bash
set -euo pipefail

buildkite-agent artifact download "Frameworks/**/*" "Frameworks" --step "buildkite.sh"
cd apps/DemoApp
pod deintegrate && pod install
xcodebuild -workspace DemoApp.xcworkspace \
           -scheme "DemoApp" \
           -destination 'platform=iOS Simulator,name=iPhone 11,OS=14.1' \
           test
