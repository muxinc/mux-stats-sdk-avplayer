#!/bin/bash
set -euo pipefail

cd MUXSDKStats
pod deintegrate && pod install
cd ..
./update-release-frameworks.sh
zip -r MUXSDKStats.framework.zip Frameworks
