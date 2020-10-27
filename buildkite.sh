#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod deintegrate && pod install
cd ..
./update-release-frameworks.sh
buildkite-agent artifact upload "Frameworks/**/*"
