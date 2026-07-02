#!/usr/bin/env bash
set -euo pipefail

# Verify the CocoaPods artifacts (built by build-pod.sh) and upload them to the
# tag's draft GitHub release. Runs in the Buildkite tag build.
# Needs `gh` and a GITHUB_TOKEN with contents:write on this repo (from the agent).
# The release workflow normally creates the draft; this creates it as a fallback.

readonly ZIP_NAME="Cocoapods-Mux-Stats-AVPlayer.zip"
readonly PODSPEC_NAME="Mux-Stats-AVPlayer.podspec"

function die {
    echo "$@" >&2
    exit 1
}

function require_command {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# sha256 the podspec declares for its source zip (`:sha256 => '...'`).
function podspec_checksum {
    awk -F"'" '/:sha256[[:space:]]*=>/ { print $2; exit }' "$1"
}

require_command gh
require_command jq
require_command shasum

# Version = the tag being built (BUILDKITE_TAG); VERSION overrides for local runs.
VERSION="${VERSION:-${BUILDKITE_TAG:-}}"
[[ -n "$VERSION" ]] \
    || die "No version found. Set BUILDKITE_TAG (tag build) or VERSION (local)."
[[ "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || die "VERSION must look like vX.Y.Z or X.Y.Z (got '$VERSION')."

readonly RELEASE_VERSION="${VERSION#v}"
readonly RELEASE_TAG="v$RELEASE_VERSION"
readonly GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-muxinc/mux-stats-sdk-avplayer}"
readonly ARTIFACTS_DIR="${ARTIFACTS_DIR:-.build/artifacts}"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    export GH_TOKEN="$GITHUB_TOKEN"
fi
[[ -n "${GH_TOKEN:-}" ]] \
    || die "No GitHub token. Set GITHUB_TOKEN (or GH_TOKEN) in the agent environment."

readonly zip_path="$ARTIFACTS_DIR/$ZIP_NAME"
readonly podspec_path="$ARTIFACTS_DIR/$PODSPEC_NAME"

[[ -f "$zip_path" ]] || die "Missing artifact: $zip_path (did build-pod.sh run?)"
[[ -f "$podspec_path" ]] || die "Missing artifact: $podspec_path (did build-pod.sh run?)"

grep -q "s.version *= *'$RELEASE_VERSION'" "$podspec_path" \
    || die "Podspec version does not match $RELEASE_VERSION."
grep -q "releases/download/$RELEASE_TAG/$ZIP_NAME" "$podspec_path" \
    || die "Podspec source URL does not point at releases/download/$RELEASE_TAG/$ZIP_NAME."

expected_checksum="$(podspec_checksum "$podspec_path")"
[[ -n "$expected_checksum" ]] || die "Podspec does not contain a :sha256 source checksum."

actual_checksum="$(shasum -a 256 "$zip_path" | awk '{ print $1 }')"
[[ "$actual_checksum" == "$expected_checksum" ]] || die "Zip checksum does not match podspec checksum.
Expected: $expected_checksum
Actual:   $actual_checksum"

echo "Verified artifacts for $RELEASE_TAG:"
ls -lh "$zip_path" "$podspec_path"

if release_json="$(gh release view "$RELEASE_TAG" --repo "$GITHUB_REPOSITORY" --json isDraft 2>/dev/null)"; then
    [[ "$(echo "$release_json" | jq --raw-output '.isDraft')" == "true" ]] \
        || die "Release $RELEASE_TAG is already published. Refusing to modify a published release."
    echo "Using draft release $RELEASE_TAG."
else
    # Fallback: normally the release workflow creates the draft; create it here
    # for a manually pushed tag or a workflow re-run.
    echo "Draft release $RELEASE_TAG not found; creating it (fallback)."
    gh release create "$RELEASE_TAG" \
        --repo "$GITHUB_REPOSITORY" \
        --draft \
        --verify-tag \
        --title "$RELEASE_TAG" \
        --generate-notes
fi

gh release upload "$RELEASE_TAG" "$zip_path" "$podspec_path" \
    --repo "$GITHUB_REPOSITORY" \
    --clobber

assets_json="$(gh release view "$RELEASE_TAG" --repo "$GITHUB_REPOSITORY" --json assets,url)"
for asset_name in "$ZIP_NAME" "$PODSPEC_NAME"; do
    echo "$assets_json" | jq --exit-status --arg name "$asset_name" \
        '.assets[] | select(.name == $name)' >/dev/null \
        || die "Release $RELEASE_TAG is missing expected asset: $asset_name"
done

echo "Attached assets to draft release $RELEASE_TAG:"
echo "$assets_json" | jq --raw-output '.assets[] | " - \(.name)"'
echo "Draft release: $(echo "$assets_json" | jq --raw-output '.url')"
echo "Next: review the draft release notes and publish it manually."
