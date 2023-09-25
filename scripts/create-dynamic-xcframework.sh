#!/bin/bash
set -euo pipefail

BUILD_DIR=$PWD/MUXSDKStats/xc
PROJECT=$PWD/MUXSDKStats/MUXSDKStats.xcodeproj
TARGET_DIR=$PWD/XCFramework


# Delete the old stuff
rm -Rf $TARGET_DIR

# Make the build directory
mkdir -p $BUILD_DIR
# Make the target directory
mkdir -p $TARGET_DIR

################ Build MuxCore SDK

xcodebuild clean archive \
    -scheme MUXSDKStatsTv \
    -project $PROJECT \
    -destination "generic/platform=tvOS" \
    -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

xcodebuild clean archive \
    -scheme MUXSDKStatsTv \
    -project $PROJECT \
    -destination "generic/platform=tvOS Simulator" \
    -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

xcodebuild clean archive \
    -scheme MUXSDKStats \
    -project $PROJECT \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/MUXSDKStats.iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

xcodebuild clean archive \
    -scheme MUXSDKStats \
    -project $PROJECT \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

xcodebuild clean archive \
    -scheme MUXSDKStats \
    -project $PROJECT \
    -destination "generic/platform=macOS,variant=Mac Catalyst" \
    -archivePath "$BUILD_DIR/MUXSDKStats.macOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify
  
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -output "$TARGET_DIR/MUXSDKStats.xcframework" | xcbeautify

rm -Rf $BUILD_DIR
