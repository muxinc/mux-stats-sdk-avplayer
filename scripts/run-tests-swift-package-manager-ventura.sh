#!/bin/bash
set -euo pipefail

readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
readonly PROJECT=MUXSDKStatsExampleSPM.xcodeproj
readonly SCHEME=MUXSDKStatsExampleSPM

readonly TEST_ARTIFACTS_DIR=$PWD/test-artifacts
readonly TEST_RESULT_BUNDLE_DIR=$TEST_ARTIFACTS_DIR/test-result-bundle
readonly TEST_RESULT_BUNDLE_FILE_PATH=$TEST_RESULT_BUNDLE_DIR/mux-stats-sdk-avplayer-ui-tests-spm.xcresult
readonly TEST_RESULT_BUNDLE_EXPORTED_ATTACHMENTS_DIR=$TEST_ARTIFACTS_DIR/test-result-bundle-attachments

if ! command -v xcbeautify &> /dev/null
then
    echo -e "\033[1;31m ERROR: xcbeautify could not be found please install it... \033[0m"
    exit 1
fi

echo "▸ Current Xcode: $(xcode-select -p)"

echo "▸ Using Xcode Version: ${XCODE}"

echo "▸ Available Xcode SDKs"
xcodebuild -showsdks

echo "▸ Unzipping downloaded xcframework bundle"
unzip -o "XCFramework/MUXSDKStats.xcframework.zip"

echo "▸ Removing test artifacts"

rm -Rf $TEST_ARTIFACTS_DIR

echo "▸ Creating test artifacts directory"
mkdir -p $TEST_ARTIFACTS_DIR

echo "▸ Creating exported test result bundle attachments directory"
mkdir -p $TEST_RESULT_BUNDLE_EXPORTED_ATTACHMENTS_DIR

cd apps/MUXSDKStatsExampleSPM

echo "▸ Resolving package dependencies"
xcodebuild -resolvePackageDependencies \
           -project MUXSDKStatsExampleSPM.xcodeproj | xcbeautify

echo "▸ Available Schemes in $(pwd)"
xcodebuild -list -json

echo "▸ Running ${SCHEME} Test when installed using Swift Package Manager"
echo ""

echo "▸ Testing SDK on iOS 17.5 - iPhone 15 Pro Max"
echo ""

xcodebuild clean test \
    -project MUXSDKStatsExampleSPM.xcodeproj \
    -scheme "MUXSDKStatsExampleSPM" \
    -resultBundlePath $TEST_RESULT_BUNDLE_FILE_PATH \
    -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro Max' | xcbeautify

cd ../..

echo "▸ Exporting test result bundle attachments"
xcrun xcresulttool export attachments --path $TEST_RESULT_BUNDLE_FILE_PATH \
                                      --output-path $TEST_RESULT_BUNDLE_EXPORTED_ATTACHMENTS_DIR

rm -Rf test-artifacts.zip

zip -ry test-artifacts.zip $TEST_ARTIFACTS_DIR
