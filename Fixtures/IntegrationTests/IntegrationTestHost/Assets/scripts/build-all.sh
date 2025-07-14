#!/bin/bash
PACKAGE_ASSETS_DIR="../../../../Packages/IntegrationTestAssets/Sources/IntegrationTestAssets/assets"
mkdir -p "$PACKAGE_ASSETS_DIR"
export ASSETS_DIR="$PACKAGE_ASSETS_DIR"
bash ./scripts/download-inputs.sh
bash ./scripts/assets-make-segments.sh
bash ./scripts/assets-make-variants.sh
bash ./scripts/assets-make-cmaf.sh
bash ./scripts/assets-make-encrypted.sh
echo "✅ All assets generated successfully!"
