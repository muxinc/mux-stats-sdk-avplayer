#!/bin/bash
CURRENT_DIR=$PWD

ASSETS_DIR=$PWD/assets
CMAF_DIR=$ASSETS_DIR/cmaf

INPUT_MP4_360=$ASSETS_DIR/input_360p.mp4

MAIN_M3U8=index_cmaf.m3u8
VARIANT_M3U8=%v/index.m3u8

mkdir -p "$CMAF_DIR/video" "$CMAF_DIR/audio"

cd $CMAF_DIR

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
  -hls_fmp4_init_filename "%v_init.mp4" \
  -hls_segment_filename "%v/%d.m4s" \
  -master_pl_name "index_cmaf.m3u8" \
  -hls_flags independent_segments \
  -movflags cmaf \
  "%v/index.m3u8"

cd $CURRENT_DIR

echo "CREATED $CMAF_DIR $CMAF_DIR/video" "$CMAF_DIR/audio"