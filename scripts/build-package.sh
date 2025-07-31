#!/bin/bash
set -euo pipefail

# set -x

readonly SCHEME=MUXSDKStats

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

readonly XCRESULT_NAME_BASE="$SCHEME-Build"
readonly XCRESULT_FILENAME="$XCRESULT_NAME_BASE.xcresult"
readonly XCRESULT_ARTIFACT_PATH="$ARTIFACTS_DIR/$XCRESULT_FILENAME.zip"

# Prepare:

EXIT_CODE=0

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"
rm -rf "$XCRESULT_ARTIFACT_PATH"

XCRESULT_BUNDLE_PATHS=()

function merge_and_export_result_bundles {
    local merged_xcresult_path="$BUILD_DIR/$XCRESULT_FILENAME"
    rm -rf "$merged_xcresult_path"

    [[ "${#XCRESULT_BUNDLE_PATHS[@]}" -gt 0 ]] || return

    if [ "${#XCRESULT_BUNDLE_PATHS[@]}" -eq 1 ]; then
        cp -ac "${XCRESULT_BUNDLE_PATHS[0]}" "$merged_xcresult_path"
    else
        xcrun xcresulttool merge --output-path "$merged_xcresult_path" "${XCRESULT_BUNDLE_PATHS[@]}"
    fi

    (cd "$BUILD_DIR" && ditto -c -k -X --keepParent "$XCRESULT_FILENAME" "$XCRESULT_ARTIFACT_PATH")
}

function build_for {
    local platform="$1"

    echo "--- Building (with static analysis) in Release mode for $platform"

    local safe_platform="${platform//[^[:alnum:]]/_}"
    local result_bundle_path="$BUILD_DIR/$XCRESULT_NAME_BASE-$safe_platform.xcresult"

    rm -rf "$result_bundle_path"

    set +e
    xcodebuild clean build \
        -scheme "$SCHEME" \
        -destination "generic/platform=$platform" \
        -configuration "Release" \
        -resultBundlePath "$result_bundle_path" \
        -disableAutomaticPackageResolution \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        GCC_TREAT_WARNINGS_AS_ERRORS=YES \
        SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
        RUN_CLANG_STATIC_ANALYZER=YES \
        CLANG_STATIC_ANALYZER_MODE=deep \
        | xcbeautify
    local xcodebuild_exit_code="$?"
    set -e

    if [ -d "$result_bundle_path" ]; then
        XCRESULT_BUNDLE_PATHS+=("$result_bundle_path")
    fi

    if [ "$xcodebuild_exit_code" -ne 0 ]; then
        echo "^^^ +++"
        echo "xcodebuild exited with code $xcodebuild_exit_code"
        EXIT_CODE=1
    fi
}

# Execute:

build_for 'iOS'
build_for 'iOS Simulator'
build_for 'macOS,variant=Mac Catalyst'
build_for 'tvOS'
build_for 'tvOS Simulator'
build_for 'visionOS'
build_for 'visionOS Simulator'

merge_and_export_result_bundles

exit "$EXIT_CODE"
