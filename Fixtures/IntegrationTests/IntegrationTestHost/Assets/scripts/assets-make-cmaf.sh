#!/bin/bash
CURRENT_DIR=$PWD

ASSETS_DIR=$PWD/assets

INPUT_MP4_360=$ASSETS_DIR/input_360p.mp4

mkdir -p "$ASSETS_DIR"

cd $ASSETS_DIR

ffmpeg -v error -y -i "$INPUT_MP4_360" \
  -t 20 \
  -c:v libx264 -c:a aac \
  -g 150 -keyint_min 150 -sc_threshold 0 \
  -force_key_frames "expr:gte(t,n_forced*5)" \
  -map 0:v -map 0:a:0 -f hls \
  -var_stream_map "v:0,agroup:group_id,name:video a:0,agroup:group_id,name:audio" \
  -hls_time 5 \
  -hls_playlist_type vod \
  -hls_segment_type fmp4 \
  -hls_fmp4_init_filename "cmaf_%v_init.mp4" \
  -hls_segment_filename "cmaf_%v_%d.m4s" \
  -master_pl_name "index_cmaf.m3u8" \
  -hls_flags independent_segments \
  -movflags cmaf \
  "cmaf_%v_index.m3u8"

cd $CURRENT_DIR

echo "CREATED CMAF assets with cmaf_ prefix"