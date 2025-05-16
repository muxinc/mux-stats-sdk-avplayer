#!/bin/bash
set -euo pipefail

readonly WORKSPACE_PATH="$PWD/Fixtures/IntegrationTests/IntegrationTests.xcworkspace"
readonly SCHEME=BrowserStackTests
readonly TEST_PLAN=CIPipeline

readonly BUILD_DIR="$PWD/.build"
readonly ARTIFACTS_DIR="$BUILD_DIR/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

readonly TEST_SUITE_ZIP="$ARTIFACTS_DIR/browserstack-test-suite.zip"
readonly BROWSERSTACK_PROJECT="AVPlayer MUXSDKStats Integration Tests"

if [ "${CI:-}" ]; then
    # Check CI credentials
    if [[ -z "${BUILDKITE_MAC_STADIUM_BROWSERSTACK_USERNAME:-}" || -z "${BUILDKITE_MAC_STADIUM_BROWSERSTACK_ACCESS_KEY:-}" ]]; then
    echo "Error: BUILDKITE_MAC_STADIUM_BROWSERSTACK_USERNAME and/or BUILDKITE_MAC_STADIUM_BROWSERSTACK_ACCESS_KEY are not set."
    
    exit 1
    fi

    export BROWSERSTACK_USERNAME=$BUILDKITE_MAC_STADIUM_BROWSERSTACK_USERNAME 
    export BROWSERSTACK_ACCESS_KEY=$BUILDKITE_MAC_STADIUM_BROWSERSTACK_ACCESS_KEY

    (cd Configuration && ln -sF CodeSigning.mux.xcconfig CodeSigning.local.xcconfig)
fi

# Check credentials
if [[ -z "${BROWSERSTACK_USERNAME:-}" || -z "${BROWSERSTACK_ACCESS_KEY:-}" ]]; then
  echo "Error: BROWSERSTACK_USERNAME and/or BROWSERSTACK_ACCESS_KEY are not set."

  exit 1
fi

EXIT_CODE=0

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"

function test_for {
    local platform="$1"
    local safe_platform="${platform//[^[:alnum:]]/_}"
    local test_products_filename="$SCHEME-$safe_platform.xctestproducts"
    local test_products_path="$BUILD_DIR/$test_products_filename"

    echo "--- Building tests for $platform"
    rm -rf "$test_products_path"
    
    set +e
    xcodebuild clean build-for-testing \
        -testProductsPath "$test_products_path" \
        -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME" \
        -testPlan "$TEST_PLAN" \
        -destination "generic/platform=$platform" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -allowProvisioningUpdates \
        -disableAutomaticPackageResolution \
        | xcbeautify
    set -e

    local xcodebuild_exit="$?"
    if [ "$xcodebuild_exit" -ne 0 ]; then
        echo "^^^ +++"
        echo "xcodebuild exited with code $xcodebuild_exit"
        EXIT_CODE=1
        return
    fi

    echo "--- Zipping test suite for BrowserStack"
    local test_host_app_dir
    test_host_app_dir=$(find "$test_products_path" -name "UnitTestsHost.app" -type d | head -n1)
    if [ -z "$test_host_app_dir" ]; then
        echo "Test host .app not found"
        EXIT_CODE=1
        return
    fi

    local xctestrun_file
    xctestrun_file=$(find "$test_products_path" -name "*.xctestrun" -type f | head -n1)
    if [ -z "$xctestrun_file" ]; then
        echo ".xctestrun file not found"
        EXIT_CODE=1
        return
    fi

    # Create temp directory to hold both
    local temp_bundle_dir="$BUILD_DIR/browserstack_bundle"
    rm -rf "$temp_bundle_dir"
    mkdir -p "$temp_bundle_dir"

    cp -R "$test_host_app_dir" "$temp_bundle_dir/"
    cp "$xctestrun_file" "$temp_bundle_dir/"

    # Create the ZIP
    rm -f "$TEST_SUITE_ZIP"
    (cd "$temp_bundle_dir" && zip --symlinks -rq  "$TEST_SUITE_ZIP" *)

    echo "Test suite bundle created at $TEST_SUITE_ZIP"
}

function upload_browserstack_test_suite {
    local test_suite_id="$1"

    local response
    response=$(curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
        -X POST "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/test-suite" \
        -F "file=@$TEST_SUITE_ZIP" \
        -F "custom_id=$test_suite_id")

    echo "$response"
}

function run_browserstack_build {
    local test_url="$1"
    local target_devices="$2" # [\"iPhone 14\"],

    local response
    response=$(curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
        -X POST "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/xctestrun-build" \
        -H "Content-Type: application/json" \
        -d "{
                \"testSuite\": \"$test_url\",
                \"devices\": $target_devices,
                \"enableResultBundle\": true,
                \"project\": \"$BROWSERSTACK_PROJECT\"
            }")

    echo "$response"
}

function await_browserstack_build {
    local build_id="$1"

    if [[ "$build_id" == bs://* ]]; then
        build_id="${build_id#bs://}"
    fi

    max_attempts=20
    attempt=1
    poll_interval=30  # seconds
    
    while (( attempt <= max_attempts )); do
        echo "Polling attempt $attempt of $max_attempts..."
        build_status=$(curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
            -X GET "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/builds/$build_id" | jq -r '.status')

        echo "Build status: $build_status"
        if [[ "$build_status" != "queued" && "$build_status" != "running" ]]; then
            break
        fi
        
        if (( attempt == max_attempts )); then
            echo "❌ Max polling attempts reached, exiting." >&2
            exit 1
        fi

        ((attempt++))
        sleep "$poll_interval"
    done            
}

function get_browserstack_test_results {
    build_id="$1"

    local build_details_json
    build_details_json=$(curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
                -X GET "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/builds/$build_id")

    echo $build_details_json | jq -c '.devices[]' | while read -r device; do
        device_name=$(echo "$device" | jq -r '.device')
        os_version=$(echo "$device" | jq -r '.os_version')
        session_id=$(echo "$device" | jq -r '.sessions[0].id') # TODO: Here we could iterate through different shards in the device (if previously set)

        if [[ -z "$session_id" || "$session_id" == "null" ]]; then
            echo "❌ No session found for $device_name $os_version"
            continue
        fi

        safe_name="${device_name// /_}_iOS_${os_version//./_}.xcresult"
        echo "📦 Downloading result bundle for $safe_name (session: $session_id)"

        curl -s -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
            -X GET "https://api-cloud.browserstack.com/app-automate/xcuitest/v2/builds/$build_id/sessions/$session_id/resultbundle" \
            -o "$ARTIFACTS_DIR/${safe_name}.zip"
    done

}

function run_ci_tests {
    if [ ! -f "$TEST_SUITE_ZIP" ]; then
        echo "No test suite zip found to upload."
        EXIT_CODE=1
        return
    fi

    local test_suite="UnitTestsHost"

    ## Upload Test Suite
    echo "--- Uploading test suite to BrowserStack"
    local test_suite_response=$(upload_browserstack_test_suite "$test_suite" 2>&1)
    local test_suite_url
    test_suite_url=$(echo "$test_suite_response" | grep -o '"test_suite_url":"[^"]*' | cut -d'"' -f4)
    if [ -z "$test_suite_url" ]; then
        echo "Failed to upload test suite to BrowserStack"
        EXIT_CODE=1
        return
    fi
    echo "Test suite uploaded successfully: $test_suite_url"


    ## Execute Build
    echo "--- Running test suite in BrowserStack"
    local build_response=$(run_browserstack_build "$test_suite_url" '["iPhone 16e-18"]' 2>&1)
    local build_id
    build_id=$(echo "$build_response" | grep -o '"build_id":"[^"]*' | cut -d'"' -f4)
    if [ -z "$build_id" ]; then
        echo "Failed to run build"
        EXIT_CODE=1
        return
    fi
    echo "Build executed successfully: $build_id"

    ## Awaiting for build execution
    echo "--- Polling BrowserStack for build: $build_id"
    await_browserstack_build "$build_id"

    ## Retrieving results
    echo "--- Retrieving results for: $build_id"
    get_browserstack_test_results "$build_id"
}

# Execute:

test_for "iOS"

run_ci_tests

exit "$EXIT_CODE"