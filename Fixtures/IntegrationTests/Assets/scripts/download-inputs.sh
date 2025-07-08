#!/bin/bash

ASSETS_DIR=./assets
TEST_CASES_DIR=./test-cases

DOWNLOAD_FROM=https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v
INPUT_MP4="$TEST_CASES_DIR/input.mp4"
INPUT_MP4_240="$ASSETS_DIR/input_240p.mp4"
INPUT_MP4_360="$ASSETS_DIR/input_360p.mp4"

OUTPUT=($INPUT_MP4 $INPUT_MP4_240 $INPUT_MP4_360)

mkdir -p $ASSETS_DIR

ffmpeg -v error -y -i $DOWNLOAD_FROM \
  -t 20 \
  -c copy \
  "$INPUT_MP4"

ffmpeg -v error -y -i "$INPUT_MP4" \
  -vf scale=426:240 \
  -c:v libx264 -b:v 200k -preset veryfast \
  -c:a aac -b:a 64k \
  "$INPUT_MP4_240"

ffmpeg -v error -y -i "$INPUT_MP4" \
  -vf scale=640:360 \
  -c:v libx264 -b:v 400k -preset veryfast \
  -c:a aac -b:a 64k \
  "$INPUT_MP4_360"

echo "CREATED $INPUT_MP4 $INPUT_MP4_240 $INPUT_MP4_360"