#!/bin/bash
CURRENT_DIR=$PWD

# Use the exported ASSETS_DIR from build-all.sh
ASSETS_DIR=${ASSETS_DIR:-$PWD/assets}

# Input file is generated in the SPM package assets directory
INPUT_MP4_360="$ASSETS_DIR/input_360p.mp4"

mkdir -p "$ASSETS_DIR/cmaf/video"
mkdir -p "$ASSETS_DIR/cmaf/audio"

cd $ASSETS_DIR/cmaf

ffmpeg -v error -y -i "../input_360p.mp4" \
  -t 20 \
  -c:v libx264 -c:a aac \
  -g 150 -keyint_min 150 -sc_threshold 0 \
  -force_key_frames "expr:gte(t,n_forced*5)" \
  -map 0:v -map 0:a \
  -f hls \
  -var_stream_map "v:0,agroup:audio,name:video a:0,agroup:audio,name:audio" \
  -hls_time 5 \
  -hls_playlist_type vod \
  -hls_segment_type fmp4 \
  -hls_fmp4_init_filename "%v_init.mp4" \
  -hls_segment_filename "%v_%d.m4s" \
  -master_pl_name "index.m3u8" \
  -hls_flags independent_segments \
  -movflags cmaf \
  "%v.m3u8"

# Organize files into proper structure
mv video_init.mp4 video_*.m4s video/
mv audio_init.mp4 audio_*.m4s audio/
mv video.m3u8 video/index.m3u8
mv audio.m3u8 audio/index.m3u8

# Rename files to remove prefixes
cd video
mv video_init.mp4 init.mp4 2>/dev/null || true
for f in video_*.m4s; do 
  [ -f "$f" ] && mv "$f" "${f#video_}"
done

cd ../audio
mv audio_init.mp4 init.mp4 2>/dev/null || true
for f in audio_*.m4s; do 
  [ -f "$f" ] && mv "$f" "${f#audio_}"
done

cd $CURRENT_DIR

echo "CREATED CMAF assets in proper folder structure"