#!/bin/bash
set -euo pipefail

# set -x

readonly WORKSPACE_PATH="$PWD/Fixtures/IntegrationTests/IntegrationTests.xcworkspace"
readonly SCHEME=MUXSDKStats
readonly TEST_PLAN=CIPipeline

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

# re-exported so saucectl CLI can use them
if [ "${CI:-}" ]; then
    export SAUCE_USERNAME=$BUILDKITE_MAC_STADIUM_SAUCE_USERNAME
    export SAUCE_ACCESS_KEY=$BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY
fi

# Prepare:

EXIT_CODE=0

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"

if [ "${CI:-}" ]; then
    (cd Configuration && ln -sF CodeSigning.mux.xcconfig CodeSigning.local.xcconfig)
fi

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
        -skip-testing "BandwidthMetricEvents" \
        -testProductsPath "$test_products_path" \
        -destination "generic/platform=$platform" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -allowProvisioningUpdates \
        -disableAutomaticPackageResolution \
        | xcbeautify
    local xcodebuild_build_exit_code="$?"
    set -e

    if [ "$xcodebuild_build_exit_code" -ne 0 ]; then
        echo "^^^ +++"
        echo "xcodebuild exited with code $xcodebuild_build_exit_code"
        EXIT_CODE=1
        return
    fi
}

function run_ci_tests {
    echo "--- Running Sauce Labs Tests"

    saucectl run #\
        #--select-suite 'Debug iOS - All Tests - iPhone 16e'
}

# Execute:

test_for 'iOS'

run_ci_tests

exit "$EXIT_CODE"
