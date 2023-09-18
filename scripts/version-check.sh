#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 path to the podspec"
    exit 1
fi

readonly COCOAPOD_SPEC="$1"

echo "Validating ${COCOAPOD_SPEC}"

# Extracts the pod spec version in the form of a MAJOR.MINOR.PATCH string
cocoapod_spec_version=$(grep -Eo '\b[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+)?(\+[0-9A-Za-z-]+)?\b' $COCOAPOD_SPEC | awk 'NR==1')

echo "Detected Cocoapod Spec Version: ${cocoapod_spec_version}"

# Checks branch name for a v followed by a semantic version MAJOR.MINOR.PATCH string
release_version=$(git branch --show-current | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

echo "Inferred Release Version: ${release_version}"

if [ "${cocoapod_spec_version}" == "${release_version}" ]; then
	echo "Versions match"
else
    echo "Versions do not match, please update ${COCOAPOD_SPEC} to ${release_version}"
    exit 1
fi
