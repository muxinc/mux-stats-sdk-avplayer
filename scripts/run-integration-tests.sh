#!/bin/bash
set -euo pipefail

# set -x

readonly WORKSPACE_PATH="$PWD/Fixtures/IntegrationTests/IntegrationTests.xcworkspace"
readonly SCHEME=MUXSDKStats
readonly TEST_PLAN=MUXSDKStats

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

readonly XCRESULT_NAME_BASE="$SCHEME-Test"
readonly XCRESULT_FILENAME="$XCRESULT_NAME_BASE.xcresult"
readonly XCRESULT_ARTIFACT_PATH="$ARTIFACTS_DIR/$XCRESULT_FILENAME.zip"

# Prepare:

EXIT_CODE=0

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"
rm -rf "$XCRESULT_ARTIFACT_PATH"

if [ "${CI:-}" ]; then
    (cd Configuration && ln -sF CodeSigning.mux.xcconfig CodeSigning.local.xcconfig)
fi

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

    (cd "$BUILD_DIR" && ditto -c -k -X "$XCRESULT_FILENAME" "$XCRESULT_ARTIFACT_PATH")
}

function test_for {
    local platform="$1"
    local destination_name="${2:-}"

    echo "--- Building tests for $platform"

    local safe_platform="${platform//[^[:alnum:]]/_}"
    local test_products_filename="$SCHEME-$safe_platform.xctestproducts"
    local test_products_path="$BUILD_DIR/$test_products_filename"

    rm -rf "$test_products_path"

    # Do not specialize the build (use generic platform)
    set +e
    xcodebuild clean build-for-testing \
        -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME" \
        -testPlan "$TEST_PLAN" \
        -testProductsPath "$test_products_path" \
        -destination "generic/platform=$platform" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -allowProvisioningUpdates \
        -disableAutomaticPackageResolution \
        | xcbeautify
    set -e
    local xcodebuild_build_exit_code="$?"

    if [ "$xcodebuild_build_exit_code" -ne 0 ]; then
        echo "^^^ +++"
        echo "xcodebuild exited with code $xcodebuild_build_exit_code"
        EXIT_CODE=1
        return
    fi

    if [ -z "$destination_name" ]; then
        echo "--- No destinations to test for $platform, exporting testable bundle"

        local test_products_artifact_path="$ARTIFACTS_DIR/$test_products_filename.zip"

        rm -rf "$test_products_artifact_path"

        (cd "$BUILD_DIR" && ditto -c -k -X "$test_products_filename" "$test_products_artifact_path")
        return
    fi

    echo "--- Testing $platform via $destination_name"

    local result_bundle_path="$BUILD_DIR/$XCRESULT_NAME_BASE-$safe_platform.xcresult"

    rm -rf "$result_bundle_path"

    set +e
    xcodebuild test-without-building \
        -testProductsPath "$test_products_path" \
        -destination "platform=$platform,name=$destination_name" \
        -resultBundlePath "$result_bundle_path" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -disableAutomaticPackageResolution \
        | xcbeautify
    local xcodebuild_test_exit_code="$?"
    set -e

    if [ -d "$result_bundle_path" ]; then
        XCRESULT_BUNDLE_PATHS+=("$result_bundle_path")
    fi

    if [ "$xcodebuild_test_exit_code" -ne 0 ]; then
        echo "^^^ +++"
        echo "xcodebuild exited with code $xcodebuild_test_exit_code"
        EXIT_CODE=1
        return
    fi
}

# Execute:

test_for 'iOS'
test_for 'iOS Simulator' 'iPhone 16 Pro'
test_for 'macOS,variant=Mac Catalyst' 'My Mac'
test_for 'tvOS'
test_for 'tvOS Simulator' 'Apple TV 4K (3rd generation) (at 1080p)'
test_for 'visionOS'
test_for 'visionOS Simulator' 'Apple Vision Pro'

merge_and_export_result_bundles

exit "$EXIT_CODE"
