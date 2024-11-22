#!/bin/bash
set -euo pipefail

if ! command -v xcbeautify &> /dev/null
then
  echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

if [[ $(git branch --show-current | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/') == $(git branch --show-current) ]]; then
    readonly RELEASE_VERSION="4.2.0"
    echo "▸ Not on a release branch. Falling back to hardcoded release version: $RELEASE_VERSION"
else
    readonly RELEASE_VERSION=$(git branch --show-current | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
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
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CLANG_ENABLE_MODULES=NO \
    MACH_O_TYPE=staticlib | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} visionOS slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create visionOS static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying visionOS Slice Version"

visionos_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStatsVision.visionOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Info.plist)"

if [ "${visionos_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ visionOS slice version ${visionos_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: visionOS slice version ${visionos_slice_version} does not match, please update ${FRAMEWORK_NAME} build settings to ${RELEASE_VERSION}"
    exit 1
fi

echo "▸ Creating visionOS Simulator archive"

xcodebuild clean archive \
    -scheme MUXSDKStatsVision \
    -project $PROJECT \
    -destination "generic/platform=visionOS Simulator" \
    -archivePath "$BUILD_DIR/MUXSDKStatsVision.visionOS-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CLANG_ENABLE_MODULES=NO \
    MACH_O_TYPE=staticlib | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} visionOS Simulator slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create visionOS Simulator static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying visionOS Simulator Slice Version"

visionos_simulator_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStatsVision.visionOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Info.plist)"

if [ "${visionos_simulator_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ visionOS Simulator slice version ${visionos_simulator_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: visionOS Simulator slice version ${visionos_simulator_slice_version} does not match, please update ${FRAMEWORK_NAME} build settings to ${RELEASE_VERSION}"
    exit 1
fi                                                                                                                                 

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

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} tvOS slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create tvOS static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying tvOS Slice Version"

tvos_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Info.plist)"

if [ "${tvos_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ tvOS slice version ${tvos_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: tvOS slice version ${tvos_slice_version} does not match expected value: ${RELEASE_VERSION}. Please update ${FRAMEWORK_NAME} CFBundleShortVersionString."
    exit 1
fi

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

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} tvOS Simulator slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create tvOS Simulator static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying tvOS Simulator Slice Version"

tvos_simulator_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Info.plist)"

if [ "${tvos_simulator_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ tvOS Simulator slice version ${tvos_simulator_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: tvOS Simulator slice version ${tvos_simulator_slice_version} does not match expected value: ${RELEASE_VERSION}. Please update ${FRAMEWORK_NAME} CFBundleShortVersionString"
    exit 1
fi

echo "▸ Creating iOS archive"

xcodebuild clean archive \
  -scheme MUXSDKStats \
  -project $PROJECT \
  -destination "generic/platform=iOS" \
  -archivePath "$BUILD_DIR/MUXSDKStats.iOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CLANG_ENABLE_MODULES=NO \
  MACH_O_TYPE=staticlib | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} iOS slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create iOS static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying iOS Slice Version"

ios_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Info.plist)"

if [ "${ios_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ iOS slice version ${ios_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: iOS slice version ${ios_slice_version} does not match expected value: ${RELEASE_VERSION}. Please update ${FRAMEWORK_NAME} CFBundleShortVersionString"
    exit 1
fi

echo "▸ Creating iOS Simulator archive"

xcodebuild clean archive \
  -scheme MUXSDKStats \
  -project $PROJECT \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CLANG_ENABLE_MODULES=NO \
  MACH_O_TYPE=staticlib | xcbeautify

if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} iOS Simulator slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create iOS Simulator static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying iOS Simulator Slice Version"

ios_simulator_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Info.plist)"

if [ "${ios_simulator_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ iOS Simulator slice version ${ios_simulator_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: iOS Simulator slice version ${ios_simulator_slice_version} does not match expected value: ${RELEASE_VERSION}. Please update ${FRAMEWORK_NAME} CFBundleShortVersionString"
    exit 1
fi

echo "▸ Creating Mac Catalyst archive"

xcodebuild clean archive \
  -scheme MUXSDKStats \
  -project $PROJECT \
  -destination "generic/platform=macOS,variant=Mac Catalyst" \
  -archivePath "$BUILD_DIR/MUXSDKStats.macOS.xcarchive" \
  SKIP_INSTALL=NO \
 BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 CLANG_ENABLE_MODULES=NO \
 MACH_O_TYPE=staticlib | xcbeautify

 if [[ $? == 0 ]]; then
    echo "▸ Successfully created ${PACKAGE_NAME} Mac Catalyst slice"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to create Mac Catalyst static library slice for ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying Mac Catalyst Slice Version"

# Note: Info.plist is in different location for macOS slices
mac_catalyst_slice_version="$(plutil -extract CFBundleShortVersionString raw \
       -o - $BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework/Resources/Info.plist)"

if [ "${mac_catalyst_slice_version}" == "${RELEASE_VERSION}" ]; then
    echo "▸ Mac Catalyst slice version ${mac_catalyst_slice_version} matches expected value"
else
    echo -e "\033[1;31m ▸ ERROR: Mac Catalyst slice version ${mac_catalyst_slice_version} does not match expected value: ${RELEASE_VERSION}. Please update ${FRAMEWORK_NAME} CFBundleShortVersionString"
    exit 1
fi

echo "▸ Creating ${PACKAGE_NAME} Static Library Multiplatform Bundle"

xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/MUXSDKStatsVision.visionOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsVision.visionOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -framework "$BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
    -output "$TARGET_DIR/MUXSDKStats.xcframework" | xcbeautify

if [[ $? == 0 ]]; then
    echo -e "\033[01;32m ▸ Successfully created ${PACKAGE_NAME} Static Library Multiplatform Bundle at ${TARGET_DIR} \033[0m"
else
    echo -e "\033[1;31m ERROR: Failed to create ${PACKAGE_NAME} Static Library Multiplatform Bundle \033[0m"
    exit 1
fi

echo "▸ Code signing ${PACKAGE_NAME} using ${CODE_SIGNING_CERTIFICATE}"

codesign --timestamp -v --sign "${CODE_SIGNING_CERTIFICATE}" "$TARGET_DIR/$PACKAGE_NAME"

if [[ $? == 0 ]]; then
    echo -e "\033[01;32m ▸ Successfully code signed ${PACKAGE_NAME} \033[0m"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to code sign ${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Verifying ${TARGET_DIR}/${PACKAGE_NAME} code signature"

codesign --verify --verbose "${TARGET_DIR}/${PACKAGE_NAME}"

if [[ $? == 0 ]]; then
    echo "▸ Verified ${PACKAGE_NAME} code signature"
else
    echo -e "\033[1;31m ▸ ERROR: Failed to verify code signature at ${TARGET_DIR}/${PACKAGE_NAME} \033[0m"
    exit 1
fi

echo "▸ Deleting old build intermediate products directory: ${BUILD_DIR}"

rm -Rf $BUILD_DIR

