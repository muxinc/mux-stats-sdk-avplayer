#!/bin/bash
CURRENT_DIR=$PWD
ASSETS_DIR=${ASSETS_DIR:-$PWD/assets}
INPUT_MP4_360="$ASSETS_DIR/input_360p.mp4"
if [ ! -f "$INPUT_MP4_360" ]; then
    echo "❌ Error: Input file $INPUT_MP4_360 not found"
    exit 1
fi
OUTPUT_FILE="$ASSETS_DIR/encrypted/index.m3u8"
KEY_HEX="0123456789abcdef0123456789abcdef"
KEY_IV_HEX="0123456789abcdef0123456789abcdef"
KEY_FILE="$ASSETS_DIR/encrypted/key.key"
KEY_INFO_FILE="$ASSETS_DIR/encrypted/key_info.txt"
KEY_URL="/normal/hls/key.key"
mkdir -p $ASSETS_DIR/encrypted
echo "$KEY_HEX" | xxd -r -p > "$KEY_FILE"
echo "$KEY_URL" > "$KEY_INFO_FILE"
echo "$KEY_FILE" >> "$KEY_INFO_FILE"
echo "$KEY_IV_HEX" >> "$KEY_INFO_FILE"
ffmpeg -v error -y -i "$INPUT_MP4_360" \
    -c:v libx264 -c:a aac \
    -g 150 -keyint_min 150 -sc_threshold 0 \
    -force_key_frames "expr:gte(t,n_forced*5)" \
    -hls_time 5 \
    -hls_playlist_type vod \
    -hls_segment_filename "$ASSETS_DIR/encrypted/%d.ts" \
    -hls_key_info_file "$KEY_INFO_FILE" \
    "$OUTPUT_FILE"
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ Error: Encrypted playlist was not created"
    exit 1
fi
