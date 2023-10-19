#!/bin/bash
set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
  echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

readonly BUILD_DIR=$PWD/MUXSDKStats/xc
readonly PROJECT=$PWD/MUXSDKStats/MUXSDKStats.xcodeproj
readonly TARGET_DIR=$PWD/XCFramework

readonly FRAMEWORK_NAME="MUXSDKStats"
readonly PACKAGE_NAME=${FRAMEWORK_NAME}.xcframework

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

echo "▸ Deleting Target Directory: ${TARGET_DIR}"
rm -Rf $TARGET_DIR

echo "▸ Creating Build Directory: ${BUILD_DIR}"
mkdir -p $BUILD_DIR

echo "▸ Creating Target Directory: ${TARGET_DIR}"
mkdir -p $TARGET_DIR                                                                                                                                                      

echo "▸ Creating tvOS archive"

xcodebuild clean archive \
  -scheme MUXSDKStatsTv \
  -project $PROJECT \
  -destination "generic/platform=tvOS" \
  -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CLANG_ENABLE_MODULES=NO \
  MACH_O_TYPE=staticlib | xcbeautify

echo "▸ Creating tvOS Simulator archive"

xcodebuild clean archive \
  -scheme MUXSDKStatsTv \
  -project $PROJECT \
  -destination "generic/platform=tvOS Simulator" \
  -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CLANG_ENABLE_MODULES=NO \
  MACH_O_TYPE=staticlib | xcbeautify

xcodebuild clean archive \
  -scheme MUXSDKStats \
  -project $PROJECT \
  -destination "generic/platform=iOS" \
  -archivePath "$BUILD_DIR/MUXSDKStats.iOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CLANG_ENABLE_MODULES=NO \
  MACH_O_TYPE=staticlib | xcbeautify

xcodebuild clean archive \
  -scheme MUXSDKStats \
  -project $PROJECT \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CLANG_ENABLE_MODULES=NO \
  MACH_O_TYPE=staticlib | xcbeautify

xcodebuild clean archive \
  -scheme MUXSDKStats \
  -project $PROJECT \
  -destination "generic/platform=macOS,variant=Mac Catalyst" \
  -archivePath "$BUILD_DIR/MUXSDKStats.macOS.xcarchive" \
  SKIP_INSTALL=NO \
 BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 CLANG_ENABLE_MODULES=NO \
 MACH_O_TYPE=staticlib | xcbeautify

 echo "▸ Creating ${PACKAGE_NAME}"

 xcodebuild -create-xcframework -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -output "$TARGET_DIR/MUXSDKStats.xcframework" | xcbeautify

echo "▸ Deleting Build Directory: ${BUILD_DIR}"

rm -Rf $BUILD_DIR
