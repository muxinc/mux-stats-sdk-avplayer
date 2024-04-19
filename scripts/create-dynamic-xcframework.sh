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

readonly CODE_SIGNING_CERTIFICATE="Apple Distribution: Mux, Inc (XX95P4Y787)"

echo "▸ Current Xcode: $(xcode-select -p)"

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

echo "▸ Creating visionOS archive"

xcodebuild clean archive \
    -scheme MUXSDKStatsVision \
    -project $PROJECT \
    -destination "generic/platform=visionOS" \
    -archivePath "$BUILD_DIR/MUXSDKStatsVision.visionOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating visionOS Simulator archive"

xcodebuild clean archive \
    -scheme MUXSDKStatsVision \
    -project $PROJECT \
    -destination "generic/platform=visionOS Simulator" \
    -archivePath "$BUILD_DIR/MUXSDKStatsVision.visionOS-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating tvOS archive"

xcodebuild clean archive \
    -scheme MUXSDKStatsTv \
    -project $PROJECT \
    -destination "generic/platform=tvOS" \
    -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating tvOS Simulator archive"

xcodebuild clean archive \
    -scheme MUXSDKStatsTv \
    -project $PROJECT \
    -destination "generic/platform=tvOS Simulator" \
    -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating iOS archive"

xcodebuild clean archive \
    -scheme MUXSDKStats \
    -project $PROJECT \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/MUXSDKStats.iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating iOS Simulator archive"

xcodebuild clean archive \
    -scheme MUXSDKStats \
    -project $PROJECT \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating Mac Catalyst archive"

xcodebuild clean archive \
    -scheme MUXSDKStats \
    -project $PROJECT \
    -destination "generic/platform=macOS,variant=Mac Catalyst" \
    -archivePath "$BUILD_DIR/MUXSDKStats.macOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "▸ Creating ${PACKAGE_NAME}"
  
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/MUXSDKStatsVision.visionOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsVision.visionOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -output "${TARGET_DIR}/${PACKAGE_NAME}" | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${FRAMEWORK_NAME} XCFramework at ${TARGET_DIR}"
else
    echo -e "\033[1;31m ERROR: Failed to create ${FRAMEWORK_NAME} XCFramework \033[0m"
    exit 1
fi

echo "▸ Code signing ${PACKAGE_NAME} using ${CODE_SIGNING_CERTIFICATE}"

codesign --timestamp -v --sign "${CODE_SIGNING_CERTIFICATE}" "$TARGET_DIR/$PACKAGE_NAME"

codesign --verify --verbose "${TARGET_DIR}/${PACKAGE_NAME}" 

echo "▸ Deleting Build Directory: ${BUILD_DIR}"

rm -Rf $BUILD_DIR
