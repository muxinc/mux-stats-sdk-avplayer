#!/bin/bash
# Use the exported ASSETS_DIR from build-all.sh
ASSETS_DIR=${ASSETS_DIR:-$PWD/assets}

INPUT_MP4_360=$ASSETS_DIR/input_360p.mp4

OUTPUT_M3U8=$ASSETS_DIR/segments/index.m3u8

mkdir -p $ASSETS_DIR/segments

ffmpeg -v error -y -i "$INPUT_MP4_360" \
  -t 20 \
  -c:v libx264 -c:a aac \
  -g 150 -keyint_min 150 -sc_threshold 0 \
  -force_key_frames "expr:gte(t,n_forced*5)" \
  -hls_flags "split_by_time+independent_segments" \
  -hls_time 5 \
  -hls_playlist_type vod \
  -hls_segment_filename "$ASSETS_DIR/segments/%d.ts" \
  $OUTPUT_M3U8

echo "CREATED $OUTPUT_M3U8"