#!/bin/bash
CURRENT_DIR=$PWD
ASSETS_DIR=$PWD/assets

INPUT_MP4_360=$ASSETS_DIR/input_360p.mp4

OUTPUT_FILE="$ASSETS_DIR/enc_index.m3u8"

# === Configuration ===
KEY_HEX="0123456789abcdef0123456789abcdef"
KEY_IV_HEX="0123456789abcdef0123456789abcdef"
KEY_FILE="key.key"
KEY_INFO_FILE="key_info.txt"
KEY_URL="/normal/hls/key.key"

mkdir -p $ASSETS_DIR

cd $ASSETS_DIR

# === Generate binary key from hex ===
echo "$KEY_HEX" | xxd -r -p > "$KEY_FILE"

# === Create key_info.txt ===
echo "$KEY_URL" > "$KEY_INFO_FILE"
echo "$KEY_FILE" >> "$KEY_INFO_FILE"
echo "$KEY_IV_HEX" >> "$KEY_INFO_FILE"

ffmpeg -v error -i $INPUT_MP4_360\
    -c:v libx264 -c:a aac \
    -g 150 -keyint_min 150 -sc_threshold 0 \
    -force_key_frames "expr:gte(t,n_forced*5)" \
    -hls_time 5 \
    -hls_playlist_type vod \
    -hls_segment_filename "enc_%d.ts" \
    -hls_key_info_file "$KEY_INFO_FILE" \
    "$OUTPUT_FILE"

cd $CURRENT_DIR

echo "CREATED $OUTPUT_FILE"
# You can test this locally with
# ffplay -allowed_extensions ALL assets/enc_index.m3u8
# NOTE: change the URL of key.key in the enc_index.m3u8 before if you want to test it locally.