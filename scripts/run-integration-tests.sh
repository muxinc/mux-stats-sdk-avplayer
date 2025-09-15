#!/bin/bash
set -euo pipefail

# set -x

# Sauce Labs credentials
export SAUCE_USERNAME=$BUILDKITE_MAC_STADIUM_SAUCE_USERNAME
export SAUCE_ACCESS_KEY=$BUILDKITE_MAC_STADIUM_SAUCE_ACCESS_KEY

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

# Use Sauce Labs configuration for CI tests
(cd Configuration && ln -sF CodeSigning.sauce.xcconfig CodeSigning.local.xcconfig)

function generate_assets {
    local original_dir="$PWD"
    
    # Navigate to the assets directory and run the generation script
    cd Fixtures/IntegrationTests/IntegrationTestHost/Assets
    
    # Ensure the target directory exists and is writable
    local target_dir="../../../../Packages/IntegrationTestAssets/Sources/IntegrationTestAssets/assets"
    mkdir -p "$target_dir"
    
    # Generate assets in a temporary location and copy them
    local temp_dir="/tmp/integration_test_assets_$$"
    mkdir -p "$temp_dir"
    export ASSETS_DIR="$temp_dir"
    
    bash scripts/download-inputs.sh
    bash scripts/assets-make-segments.sh
    bash scripts/assets-make-variants.sh
    bash scripts/assets-make-cmaf.sh
    bash scripts/assets-make-encrypted.sh
    
    # Copy generated assets to the target directory
    cp -r "$temp_dir"/* "$target_dir/" 2>/dev/null || {
        echo "❌ Failed to copy assets to target directory"
        return 1
    }
    
    rm -rf "$temp_dir"
    cd "$original_dir"
}

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

    (cd "$BUILD_DIR" && ditto -c -k --norsrc --zlibCompressionLevel 9 --keepParent "$XCRESULT_FILENAME" "$XCRESULT_ARTIFACT_PATH")
}

function test_for {
    local platform="$1"
    local destination_name="${2:-}"


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

    if [ -z "$destination_name" ]; then
        echo "--- No destinations to test for $platform, exporting testable bundle"

        local test_products_artifact_path="$ARTIFACTS_DIR/$test_products_filename.zip"

        rm -rf "$test_products_artifact_path"

        (cd "$BUILD_DIR" && ditto -c -k --norsrc --zlibCompressionLevel 9 --keepParent "$test_products_filename" "$test_products_artifact_path")
        return
    fi


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

# Create placeholder assets directory so SPM always recognizes it during package resolution
mkdir -p "Packages/IntegrationTestAssets/Sources/IntegrationTestAssets/assets"

# Install ffmpeg if needed
if ! command -v ffmpeg &> /dev/null; then
    if command -v brew &> /dev/null; then
        brew install ffmpeg
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y ffmpeg
    else
        echo "❌ Error: Cannot install ffmpeg automatically. Please install ffmpeg manually."
        exit 1
    fi
fi

generate_assets

test_for 'iOS'
test_for 'iOS Simulator' 'iPhone 16 Pro'


merge_and_export_result_bundles

exit "$EXIT_CODE"
