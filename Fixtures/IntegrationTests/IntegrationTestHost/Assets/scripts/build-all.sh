#!/bin/bash

# Path to the SPM package assets directory 
PACKAGE_ASSETS_DIR="../../../../Packages/IntegrationTestAssets/Sources/IntegrationTestAssets/assets"

# Create the package assets directory if it doesn't exist
mkdir -p "$PACKAGE_ASSETS_DIR"

# Export the assets directory for the other scripts to use
export ASSETS_DIR="$PACKAGE_ASSETS_DIR"

bash ./scripts/download-inputs.sh
bash ./scripts/assets-make-segments.sh
bash ./scripts/assets-make-variants.sh
bash ./scripts/assets-make-cmaf.sh
bash ./scripts/assets-make-encrypted.sh
