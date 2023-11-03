#!/bin/bash

if [ $# -ne 2 ]; then
    echo "▸ Usage: $0 MyPod.podspec MyFramework.json"
    exit 1
fi

readonly COCOAPOD_SPEC="$1"
readonly CARTHAGE_JSON_SPECIFICATION="$2"

echo "▸ Validating ${COCOAPOD_SPEC}"

# Extracts the pod spec version in the form of a MAJOR.MINOR.PATCH string
cocoapod_spec_version=$(grep -Eo '\b[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+)?(\+[0-9A-Za-z-]+)?\b' $COCOAPOD_SPEC | awk 'NR==1')

echo "▸ Detected Cocoapod Spec Version: ${cocoapod_spec_version}"

# Checks branch name for a v followed by a semantic version MAJOR.MINOR.PATCH string
release_version=$(git branch --show-current | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

echo "▸ Inferred Release Version: ${release_version}"

if [ "${cocoapod_spec_version}" == "${release_version}" ]; then
	echo "▸ ${COCOAPOD_SPEC} version matches release branch version"
else
    echo "▸ Versions do not match, please update ${COCOAPOD_SPEC} to ${release_version}"
    exit 1
fi

echo "▸ Checking Plugin Version Constant"

search_pattern='const MUXSDKPluginVersion = '

files=$(find "MUXSDKStats" -type f -name '*.m')

for file in $files; do
    # Use 'grep' to find lines matching the pattern
    matched_lines=$(grep -E "$search_pattern" "$file")

    # Use 'sed' to extract the version string from matched lines
    version_string=$(echo "$matched_lines" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/g')

    # Print the version string if found
    if [ -n "$version_string" ]; then
        echo "▸ Found semantic version in $file: $version_string"

        if [ "${version_string}" == "${release_version}" ]; then
            echo "▸ ${search_pattern} version matches release branch version"
        else
            echo "▸ Plugin version string: ${version_string}"
            echo "▸ Versions do not match, please update ${search_pattern} to ${release_version}"
            exit 1
        fi

        exit 0
    fi
done
