#!/bin/bash
CURRENT_DIR=$PWD
ASSETS_DIR=$PWD/assets
TEST_CASES_DIR=$PWD/test-cases

MULTI_VARIANT_DIR=$ASSETS_DIR/multivariant
SEGMENTS_240_DIR=$MULTI_VARIANT_DIR/240p
SEGMENTS_360_DIR=$MULTI_VARIANT_DIR/360p

INPUT_MP4=$TEST_CASES_DIR/input.mp4

mkdir -p $MULTI_VARIANT_DIR $SEGMENTS_240_DIR $SEGMENTS_360_DIR

cd $MULTI_VARIANT_DIR

ffmpeg -v error -y -i "$INPUT_MP4" \
  -filter_complex "[0:v]split=2[v1][v2]; \
                   [v1]scale=426:240[v240]; \
                   [v2]scale=640:360[v360]" \
  -map "[v240]" -map a \
  -map "[v360]" -map a \
  -c:v:0 libx264 -b:v:0 200k -preset veryfast \
  -c:v:1 libx264 -b:v:1 400k -preset veryfast \
  -c:a aac -b:a 64k \
  -var_stream_map "v:0,a:0,name:240p v:1,a:1,name:360p" \
  -f hls \
  -hls_time 5 \
  -hls_playlist_type vod \
  -hls_segment_filename "%v/%d.ts" \
  -master_pl_name index.m3u8 \
  "%v/index.m3u8"

cd $CURRENT_DIR

echo "CREATED $SEGMENTS_240_DIR $SEGMENTS_360_DIR"