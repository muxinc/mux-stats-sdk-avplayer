#!/bin/bash
set -euo pipefail

carthage build --no-skip-current --use-xcframeworks

if [[ $? == 0 ]]; then
    echo "▸ Successfully build Carthage XCFramework artifact"
else
    echo -e "\033[1;31m ERROR: Failed to build Carthage XCFramework artifact \033[0m"
    exit 1
fi
