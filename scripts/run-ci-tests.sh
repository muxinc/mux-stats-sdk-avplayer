#!/bin/bash
set -euo pipefail

# set -x

readonly WORKSPACE_PATH="$PWD/Fixtures/IntegrationTests/IntegrationTests.xcworkspace"
readonly SCHEME=MUXSDKStats
readonly TEST_PLAN=CIPipeline

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

# Add local saucectl to PATH if it exists
if [ -f "./bin/saucectl" ]; then
    export PATH="$PWD/bin:$PATH"
fi

# re-exported so saucectl CLI can use them
if [ "${CI:-}" ]; then
    export SAUCE_USERNAME=$BUILDKITE_MAC_STADIUM_SAUCE_USERNAME
    export SAUCE_ACCESS_KEY=$BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY
else
    # Local development credentials
    export SAUCE_USERNAME=Ignacio-mux
    export SAUCE_ACCESS_KEY=19132d53-6561-43b6-a447-c277be36625e
fi

# Prepare:

EXIT_CODE=0

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"

if [ "${CI:-}" ]; then
    (cd Configuration && ln -sF CodeSigning.sauce.xcconfig CodeSigning.local.xcconfig)
else
    (cd Configuration && ln -sF CodeSigning.mux.xcconfig CodeSigning.local.xcconfig)
fi

function generate_assets {
    local original_dir="$PWD"
    
    # Navigate to the assets directory and run the generation script
    cd Fixtures/IntegrationTests/IntegrationTestHost/Assets
    bash ./scripts/build-all.sh
    
    cd "$original_dir"
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
    # Note: removed 'clean' to preserve generated assets for SPM package resolution
    set +e
    xcodebuild build-for-testing \
        -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME" \
        -testPlan "$TEST_PLAN" \
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
    saucectl run \
        --select-suite 'Debug iOS - All Tests - iPhone 16e'
}

# Execute:

# Create placeholder assets directory so SPM always recognizes it during package resolution
mkdir -p "Packages/IntegrationTestAssets/Sources/IntegrationTestAssets/assets"

generate_assets

test_for 'iOS'

run_ci_tests

exit "$EXIT_CODE"
