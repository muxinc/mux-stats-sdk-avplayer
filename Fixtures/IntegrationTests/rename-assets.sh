#!/bin/bash

# Script to rename assets to avoid Xcode bundling conflicts
# Adds directory-based prefixes to make all filenames unique

set -e

ASSETS_DIR="assets 2"

echo "🔄 Renaming assets to avoid bundling conflicts..."

cd "Fixtures/IntegrationTests"

# Function to rename files in a directory with a prefix
rename_files() {
    local dir="$1"
    local prefix="$2"
    
    if [ -d "$ASSETS_DIR/$dir" ]; then
        echo "Processing $dir/ with prefix '$prefix'"
        
        # Rename index.m3u8 files
        if [ -f "$ASSETS_DIR/$dir/index.m3u8" ]; then
            mv "$ASSETS_DIR/$dir/index.m3u8" "$ASSETS_DIR/$dir/${prefix}_index.m3u8"
            echo "  Renamed index.m3u8 → ${prefix}_index.m3u8"
        fi
        
        # Rename numbered segment files
        for file in "$ASSETS_DIR/$dir"/{0,1,2,3,4,5,6,7,8,9}.*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                extension="${filename##*.}"
                number="${filename%.*}"
                newname="${prefix}_${number}.${extension}"
                mv "$file" "$ASSETS_DIR/$dir/$newname"
                echo "  Renamed $filename → $newname"
            fi
        done
    fi
}

# Rename assets with directory-based prefixes
rename_files "segments" "seg"
rename_files "cmaf/video" "cmaf_video"
rename_files "cmaf/audio" "cmaf_audio"
rename_files "multivariant" "multi"
rename_files "multivariant/240p" "multi_240p"
rename_files "multivariant/360p" "multi_360p"
rename_files "encrypted" "enc"

echo "✅ Asset renaming complete!"
echo ""
echo "📋 Updated filenames:"
echo "  segments/index.m3u8 → segments/seg_index.m3u8"
echo "  segments/0.ts → segments/seg_0.ts"
echo "  cmaf/video/index.m3u8 → cmaf/video/cmaf_video_index.m3u8"
echo "  cmaf/video/0.m4s → cmaf/video/cmaf_video_0.m4s"
echo "  multivariant/index.m3u8 → multivariant/multi_index.m3u8"
echo "  multivariant/240p/index.m3u8 → multivariant/240p/multi_240p_index.m3u8"
echo "  multivariant/240p/0.ts → multivariant/240p/multi_240p_0.ts"
echo ""
echo "🎯 All filenames are now unique for Xcode bundling!" 