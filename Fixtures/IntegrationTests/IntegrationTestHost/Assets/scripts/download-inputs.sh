#!/bin/bash

# Use the exported ASSETS_DIR from build-all.sh
ASSETS_DIR=${ASSETS_DIR:-./assets}
TEST_CASES_DIR=./test-cases

DOWNLOAD_FROM=https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v
INPUT_MP4="$TEST_CASES_DIR/input.mp4"
INPUT_MP4_240="$ASSETS_DIR/input_240p.mp4"
INPUT_MP4_360="$ASSETS_DIR/input_360p.mp4"

OUTPUT=($INPUT_MP4 $INPUT_MP4_240 $INPUT_MP4_360)

mkdir -p $ASSETS_DIR
mkdir -p $TEST_CASES_DIR

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Error: ffmpeg is not available. Please install ffmpeg."
    exit 1
fi

# Download the source video
if ! ffmpeg -v error -y -i "$DOWNLOAD_FROM" \
  -t 20 \
  -c copy \
  "$INPUT_MP4"; then
    echo "❌ Error: Failed to download source video"
    exit 1
fi

# Create 240p version
if ! ffmpeg -v error -y -i "$INPUT_MP4" \
  -vf scale=426:240 \
  -c:v libx264 -b:v 200k -preset veryfast \
  -c:a aac -b:a 64k \
  "$INPUT_MP4_240"; then
    echo "❌ Error: Failed to create 240p version"
    exit 1
fi

# Create 360p version
if ! ffmpeg -v error -y -i "$INPUT_MP4" \
  -vf scale=640:360 \
  -c:v libx264 -b:v 400k -preset veryfast \
  -c:a aac -b:a 64k \
  "$INPUT_MP4_360"; then
    echo "❌ Error: Failed to create 360p version"
    exit 1
fi

# Verify files were created
if [ ! -f "$INPUT_MP4_240" ] || [ ! -f "$INPUT_MP4_360" ]; then
    echo "❌ Error: Output files were not created successfully"
    exit 1
fi

echo "CREATED $INPUT_MP4 $INPUT_MP4_240 $INPUT_MP4_360"