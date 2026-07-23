#!/usr/bin/env bash
set -euo pipefail

# Create the tag and draft GitHub release for a merged releases/vX.Y.Z PR.
# Remote lookups use list endpoints: a missing tag or release is an empty,
# successful response, while authentication/network/API failures stay fatal.

function die {
    echo "$@" >&2
    exit 1
}

function require_command {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

require_command gh
require_command jq

readonly TAG="${TAG:-}"
readonly SHA="${SHA:-}"
readonly REPO="${REPO:-${GITHUB_REPOSITORY:-}}"
readonly PR_BODY="${PR_BODY:-}"

[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || die "TAG must look like vX.Y.Z (got '$TAG')."
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] \
    || die "SHA must be a 40-character lowercase commit SHA (got '$SHA')."
[[ -n "$REPO" ]] || die "REPO (or GITHUB_REPOSITORY) is required."
[[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]] \
    || die "No GitHub token. Set GH_TOKEN (or GITHUB_TOKEN)."

if [[ -n "${GITHUB_TOKEN:-}" && -z "${GH_TOKEN:-}" ]]; then
    export GH_TOKEN="$GITHUB_TOKEN"
fi

readonly expected_ref="refs/tags/$TAG"
refs_json="$(gh api "repos/${REPO}/git/matching-refs/tags/${TAG}")"
existing="$(jq --raw-output --arg ref "$expected_ref" \
    '.[] | select(.ref == $ref) | .object.sha' <<<"$refs_json")"

if [[ -z "$existing" ]]; then
    gh api "repos/${REPO}/git/refs" \
        -f ref="$expected_ref" \
        -f sha="$SHA" >/dev/null
    echo "Created tag $TAG at $SHA."
elif [[ "$existing" == "$SHA" ]]; then
    echo "Tag $TAG already exists at $SHA; continuing."
else
    die "Tag $TAG already exists but points to $existing, not $SHA."
fi

releases_json="$(gh release list \
    --repo "$REPO" \
    --limit 1000 \
    --json tagName,isDraft)"
release_state="$(jq --raw-output --arg tag "$TAG" \
    '.[] | select(.tagName == $tag) | .isDraft' <<<"$releases_json")"

case "$release_state" in
    true)
        echo "Draft release $TAG already exists; continuing."
        ;;
    false)
        die "Release $TAG already exists and is published; refusing to proceed."
        ;;
    "")
        gh release create "$TAG" \
            --repo "$REPO" \
            --draft \
            --verify-tag \
            --title "$TAG" \
            --notes "$PR_BODY" >/dev/null
        echo "Created draft release $TAG."
        ;;
    *)
        die "Unexpected release state for $TAG: $release_state"
        ;;
esac
