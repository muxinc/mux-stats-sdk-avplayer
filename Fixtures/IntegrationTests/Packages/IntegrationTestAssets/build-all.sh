#!/bin/bash

# Script to build all test assets for IntegrationTestAssets SPM package

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/Sources/IntegrationTestAssets/assets"
ORIGINAL_SCRIPTS_DIR="../../IntegrationTestHost/Assets/scripts"

echo "🔧 Building test assets for SPM package..."
echo "📁 Assets directory: $ASSETS_DIR"

# Create the base assets directory structure
mkdir -p "$ASSETS_DIR"
mkdir -p "$ASSETS_DIR/segments"
mkdir -p "$ASSETS_DIR/cmaf/video"
mkdir -p "$ASSETS_DIR/cmaf/audio"
mkdir -p "$ASSETS_DIR/multivariant/240p"
mkdir -p "$ASSETS_DIR/multivariant/360p"
mkdir -p "$ASSETS_DIR/encrypted"

# Download input files
echo "📥 Downloading input files..."
bash "$ORIGINAL_SCRIPTS_DIR/download-inputs.sh"

# Copy input files to our assets directory
cp "$ORIGINAL_SCRIPTS_DIR/../assets/input_240p.mp4" "$ASSETS_DIR/"
cp "$ORIGINAL_SCRIPTS_DIR/../assets/input_360p.mp4" "$ASSETS_DIR/"

# Generate assets with proper folder structure
echo "🎬 Generating segments..."
bash "$SCRIPT_DIR/scripts/make-segments.sh"

echo "🎬 Generating CMAF assets..."
bash "$SCRIPT_DIR/scripts/make-cmaf.sh"

echo "🎬 Generating multivariant assets..."
bash "$SCRIPT_DIR/scripts/make-multivariant.sh"

echo "🎬 Generating encrypted assets..."
bash "$SCRIPT_DIR/scripts/make-encrypted.sh"

echo "✅ All assets generated successfully!"
echo "📁 Assets are now in: $ASSETS_DIR"
