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

# Always use Sauce Labs configuration for CI tests
(cd Configuration && ln -sF CodeSigning.sauce.xcconfig CodeSigning.local.xcconfig)

function generate_assets {
    local original_dir="$PWD"
    
    # Navigate to the assets directory and run the generation script
    cd Fixtures/IntegrationTests/IntegrationTestHost/Assets
    
    # Ensure the target directory exists and is writable
    local target_dir="../../../../Packages/IntegrationTestAssets/Sources/IntegrationTestAssets/assets"
    mkdir -p "$target_dir"
    
    # Check if we can write to the target directory
    if [ ! -w "$target_dir" ]; then
        # Try to generate assets in a temporary location and copy them
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
    else
        # Normal execution
        bash scripts/build-all.sh
    fi
    
    cd "$original_dir"
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
        CODE_SIGNING_ALLOWED=NO \
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

run_ci_tests

exit "$EXIT_CODE"
