#!/bin/bash

release_version=$(echo $BUILDKITE_BRANCH | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
echo "▸ Inferred Release Version: ${release_version}"

echo "▸ Checking Plugin Version Constant"

search_pattern='const MUXSDKPluginVersion = '

files=$(find 'Sources/MUXSDKStats' -type f -name '*.m')

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
