#!/bin/bash
set -euo pipefail

# Keep this at "~> X.Y" to match the behavior of the "from:" requirement in Package.swift
readonly MUXCORE_VERSION="~> 5.5"

readonly CODE_SIGNING_IDENTITY="Apple Distribution: Mux, Inc (XX95P4Y787)"


readonly SCHEME=MUXSDKStatsFramework
readonly PROJECT=scripts/MUXSDKStatsFramework.xcodeproj

readonly PACKAGE_ROOT_PATH="$PWD"
readonly BUILD_PATH="$PWD/.build"
readonly ARTIFACTS_PATH="$BUILD_PATH/artifacts"
readonly DERIVED_DATA_PATH="$BUILD_PATH/DerivedData"

readonly XCARCHIVE_NAME_BASE="$SCHEME"

readonly XCFRAMEWORK_FILENAME="MUXSDKStats.xcframework"
readonly XCFRAMEWORK_PATH="$BUILD_PATH/$XCFRAMEWORK_FILENAME"

readonly COCOAPODS_BINARY_ARTIFACT_FILENAME="Cocoapods-Mux-Stats-AVPlayer.zip"
readonly COCOAPODS_BINARY_ARTIFACT_PATH="$ARTIFACTS_PATH/$COCOAPODS_BINARY_ARTIFACT_FILENAME"
readonly PODSPEC_ARTIFACT_PATH="$ARTIFACTS_PATH/Mux-Stats-AVPlayer.podspec"

readonly XCRESULT_NAME_BASE="$SCHEME-Build"
readonly XCRESULT_FILENAME="$XCRESULT_NAME_BASE.xcresult"
readonly XCRESULT_PATH="$BUILD_PATH/$XCRESULT_FILENAME"
readonly XCRESULT_ZIP_ARTIFACT_PATH="$ARTIFACTS_PATH/$XCRESULT_FILENAME.zip"

# Prepare:

rm -rf "$BUILD_PATH" "$ARTIFACTS_PATH"
mkdir -p "$BUILD_PATH" "$ARTIFACTS_PATH"

XCRESULT_BUNDLE_PATHS=()
XCARCHIVE_PATHS=()

function merge_and_export_result_bundles {
    [[ "${#XCRESULT_BUNDLE_PATHS[@]}" -gt 0 ]] || return

    echo "--- Exporting XCResult bundle"

    if [ "${#XCRESULT_BUNDLE_PATHS[@]}" -eq 1 ]; then
        cp -ac "${XCRESULT_BUNDLE_PATHS[0]}" "$XCRESULT_PATH"
    else
        xcrun xcresulttool merge --output-path "$XCRESULT_PATH" "${XCRESULT_BUNDLE_PATHS[@]}"
    fi

    ditto -c -k --norsrc --zlibCompressionLevel 9 --keepParent "$XCRESULT_PATH" "$XCRESULT_ZIP_ARTIFACT_PATH"
}

function build_for {
    local variant_name="$1"
    local platform="$2"

    echo "--- Archiving (with static analysis) for $platform"

    local result_bundle_path="$BUILD_PATH/$XCRESULT_NAME_BASE-$variant_name.xcresult"
    local archive_path="$BUILD_PATH/$XCARCHIVE_NAME_BASE-$variant_name.xcarchive"

    rm -rf "$result_bundle_path"

    set +e
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "generic/platform=$platform" \
        -archivePath "$archive_path" \
        -resultBundlePath "$result_bundle_path" \
        -disableAutomaticPackageResolution \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        MERGEABLE_LIBRARY=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        RUN_CLANG_STATIC_ANALYZER=YES \
        CLANG_STATIC_ANALYZER_MODE=deep \
        | xcbeautify
    local xcodebuild_exit_code="$?"
    set -e

    XCARCHIVE_PATHS+=("$archive_path")

    if [ -d "$result_bundle_path" ]; then
        XCRESULT_BUNDLE_PATHS+=("$result_bundle_path")
    fi

    if [ "$xcodebuild_exit_code" -ne 0 ]; then
        echo "^^^ +++"
        echo "xcodebuild exited with code $xcodebuild_exit_code"
        merge_and_export_result_bundles
        exit 1
    fi
}

function create_signed_xcframework {
    echo "--- Creating signed XCFramework"

    local xcodebuild_args=()
    for path in ${XCARCHIVE_PATHS[@]}; do
        xcodebuild_args+=(
            -archive "$path"
            -framework MUXSDKStats.framework
        )
    done

    xcodebuild -create-xcframework "${xcodebuild_args[@]}" -output "$XCFRAMEWORK_PATH"

    codesign --timestamp --verbose --sign "$CODE_SIGNING_IDENTITY" "$XCFRAMEWORK_PATH"

    codesign --verify --verbose "$XCFRAMEWORK_PATH" 
}

function assemble_pod {
    echo "--- Creating CocoaPods zip asset"

    local pod_contents_path="$BUILD_PATH/pod"
    rm -rf "$pod_contents_path"
    mkdir -p "$pod_contents_path"

    cp -ac "$XCFRAMEWORK_PATH" "$PACKAGE_ROOT_PATH/LICENSE" "$pod_contents_path"

    ditto -c -k --norsrc --zlibCompressionLevel 9 "$pod_contents_path" "$COCOAPODS_BINARY_ARTIFACT_PATH"
}

function generate_podpsec {
    echo "--- Generating Podspec"

    local release_version=$(defaults read "$XCFRAMEWORK_PATH/ios-arm64/MUXSDKStats.framework/Info.plist" CFBundleShortVersionString)

    local pod_zip_checksum=$(sha256 --quiet "$COCOAPODS_BINARY_ARTIFACT_PATH")

    swift package generate-podspec \
        --allow-writing-to-package-directory \
        --version "$release_version" \
        --core-version "$MUXCORE_VERSION" \
        --url "https://github.com/muxinc/stats-sdk-avplayer/releases/download/v$release_version/$COCOAPODS_BINARY_ARTIFACT_FILENAME" \
        --checksum "$pod_zip_checksum" \
        --output "$PODSPEC_ARTIFACT_PATH"
}

function lint_podspec {
    local pod_contents_path="$BUILD_PATH/pod"
    cp -ac "$PODSPEC_ARTIFACT_PATH" "$pod_contents_path"

    pushd "$pod_contents_path"
    
    echo "--- Linting Podspec (default options)"
    LC_ALL=en_US.UTF-8 pod lib lint

    echo "--- Linting Podspec (using libraries)"
    LC_ALL=en_US.UTF-8 pod lib lint --use-libraries

    echo "--- Linting Podspec (using libraries and modular headers)"
    LC_ALL=en_US.UTF-8 pod lib lint --use-libraries --use-modular-headers

    echo "--- Linting Podspec (using static frameworks)"
    LC_ALL=en_US.UTF-8 pod lib lint --use-static-frameworks

    popd
}

# Execute:

build_for iphoneos 'iOS'
build_for iphonesimulator 'iOS Simulator'
build_for maccatalyst 'macOS,variant=Mac Catalyst'
build_for appletvos 'tvOS'
build_for appletvsimulator 'tvOS Simulator'
build_for xros 'visionOS'
build_for xrsimulator 'visionOS Simulator'

merge_and_export_result_bundles

create_signed_xcframework

assemble_pod

generate_podpsec

lint_podspec
