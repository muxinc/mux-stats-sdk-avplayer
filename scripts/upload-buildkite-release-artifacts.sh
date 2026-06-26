#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_BUILDKITE_ORG="mux"
readonly DEFAULT_BUILDKITE_PIPELINE="stats-sdk-avplayer"
readonly ZIP_NAME="Cocoapods-Mux-Stats-AVPlayer.zip"
readonly PODSPEC_NAME="Mux-Stats-AVPlayer.podspec"

function require_env {
    local name="$1"
    if [[ -z "${!name:-}" ]]; then
        echo "Missing required environment variable: $name" >&2
        exit 1
    fi
}

function require_command {
    local name="$1"
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "Missing required command: $name" >&2
        exit 1
    fi
}

function buildkite_api {
    curl --fail --silent --show-error \
        -H "Authorization: Bearer $BUILDKITE_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$@"
}

function download_buildkite_artifact {
    local artifacts_json="$1"
    local artifact_name="$2"
    local artifact_url headers_path body_path redirect_url

    artifact_url="$(
        echo "$artifacts_json" \
            | jq --raw-output --arg name "$artifact_name" \
                '.[] | select(.filename == $name and .state == "finished") | .download_url' \
            | head -n 1
    )"

    if [[ -z "$artifact_url" || "$artifact_url" == "null" ]]; then
        echo "Missing finished Buildkite artifact: $artifact_name" >&2
        exit 1
    fi

    headers_path="$(mktemp)"
    body_path="$(mktemp)"

    # Do not follow the redirect with the Authorization header. Buildkite returns a
    # short-lived signed artifact URL; fetch that URL separately without credentials.
    curl --fail --silent --show-error \
        --dump-header "$headers_path" \
        --output "$body_path" \
        -H "Authorization: Bearer $BUILDKITE_API_TOKEN" \
        "$artifact_url" >/dev/null

    redirect_url="$(
        awk 'BEGIN { IGNORECASE=1 } /^location:/ { sub(/\r$/, "", $2); print $2 }' "$headers_path" \
            | tail -n 1
    )"

    if [[ -z "$redirect_url" ]]; then
        redirect_url="$(jq --raw-output '.url // empty' "$body_path" 2>/dev/null || true)"
    fi

    rm -f "$headers_path" "$body_path"

    if [[ -z "$redirect_url" ]]; then
        echo "Buildkite did not return a download URL for artifact: $artifact_name" >&2
        exit 1
    fi

    curl --fail --location --silent --show-error "$redirect_url" --output "$artifact_name"
}

function find_build_number {
    local builds_json

    builds_json="$(
        curl --fail --silent --show-error --get \
            -H "Authorization: Bearer $BUILDKITE_API_TOKEN" \
            --data-urlencode "branch=$RELEASE_BRANCH" \
            --data-urlencode "state=passed" \
            --data-urlencode "per_page=5" \
            "https://api.buildkite.com/v2/organizations/$BUILDKITE_ORG/pipelines/$BUILDKITE_PIPELINE/builds"
    )"

    echo "$builds_json" | jq --raw-output '.[0].number // empty'
}

function verify_artifacts {
    grep -q "s.version *= *'$RELEASE_VERSION'" "$PODSPEC_NAME"
    grep -q "releases/download/$RELEASE_TAG/$ZIP_NAME" "$PODSPEC_NAME"
}

require_command curl
require_command jq

require_env BUILDKITE_API_TOKEN
require_env VERSION

readonly BUILDKITE_ORG="${BUILDKITE_ORG:-$DEFAULT_BUILDKITE_ORG}"
readonly BUILDKITE_PIPELINE="${BUILDKITE_PIPELINE:-$DEFAULT_BUILDKITE_PIPELINE}"
readonly GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-muxinc/mux-stats-sdk-avplayer}"
readonly UPLOAD="${UPLOAD:-false}"

if [[ "$UPLOAD" != "true" && "$UPLOAD" != "false" ]]; then
    echo "UPLOAD must be either 'true' or 'false'." >&2
    exit 1
fi

if [[ ! "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "VERSION must look like vX.Y.Z or X.Y.Z." >&2
    exit 1
fi

readonly RELEASE_VERSION="${VERSION#v}"
readonly RELEASE_TAG="v$RELEASE_VERSION"
readonly RELEASE_BRANCH="releases/$RELEASE_TAG"

if [[ "$UPLOAD" == "true" ]]; then
    require_command gh
    require_env GITHUB_TOKEN
    export GH_TOKEN="$GITHUB_TOKEN"
fi

readonly BUILD_NUMBER="${BUILDKITE_BUILD_NUMBER:-$(find_build_number)}"

if [[ -z "$BUILD_NUMBER" ]]; then
    echo "No passed Buildkite build found for branch $RELEASE_BRANCH." >&2
    exit 1
fi

echo "Using Buildkite build: $BUILDKITE_ORG/$BUILDKITE_PIPELINE #$BUILD_NUMBER"
echo "Using release tag: $RELEASE_TAG"
echo "Upload enabled: $UPLOAD"

artifact_dir="$(mktemp -d)"
trap 'rm -rf "$artifact_dir"' EXIT

pushd "$artifact_dir" >/dev/null

artifacts_json="$(
    buildkite_api \
        "https://api.buildkite.com/v2/organizations/$BUILDKITE_ORG/pipelines/$BUILDKITE_PIPELINE/builds/$BUILD_NUMBER/artifacts"
)"

download_buildkite_artifact "$artifacts_json" "$ZIP_NAME"
download_buildkite_artifact "$artifacts_json" "$PODSPEC_NAME"

verify_artifacts

echo "Verified release artifacts:"
ls -lh "$ZIP_NAME" "$PODSPEC_NAME"

if [[ "$UPLOAD" == "true" ]]; then
    gh release view "$RELEASE_TAG" --repo "$GITHUB_REPOSITORY" >/dev/null
    gh release upload "$RELEASE_TAG" "$ZIP_NAME" "$PODSPEC_NAME" \
        --repo "$GITHUB_REPOSITORY" \
        --clobber
    echo "Uploaded artifacts to GitHub release $RELEASE_TAG."
else
    echo "Dry run complete. Set UPLOAD=true to upload artifacts to the GitHub release."
fi

popd >/dev/null
