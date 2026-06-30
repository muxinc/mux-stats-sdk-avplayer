#!/usr/bin/env bash
#
# set-version.sh — Set a new release version across the codebase.
#
# Usage:
#   scripts/set-version.sh X.Y.Z
#
# Mirrors scripts/set-version.sh in the other Mux iOS SDK repos so the release
# step is the same command everywhere. Here it updates the two files that
# hardcode the SDK version:
#   - scripts/MUXSDKStatsFramework.xcconfig        -> MARKETING_VERSION
#   - Sources/MUXSDKStats/MUXSDKPlayerBinding.m    -> MUXSDKPluginVersion
#
# It deliberately does NOT touch the MuxCore dependency version (Package.swift /
# MUXCORE_VERSION) — that is a separate dependency on its own cadence.
set -euo pipefail
IFS=$'\n\t'

# --- Locate the repository root relative to this script -----------------------
# Resolve regardless of the caller's current working directory. REPO_ROOT can be
# overridden (used by the tests).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
readonly SCRIPT_DIR REPO_ROOT

readonly XCCONFIG="${REPO_ROOT}/scripts/MUXSDKStatsFramework.xcconfig"
readonly BINDING="${REPO_ROOT}/Sources/MUXSDKStats/MUXSDKPlayerBinding.m"

# Temp file used by update_file; cleaned up on exit if a run is interrupted.
TMP_FILE=""
cleanup() {
  if [[ -n "$TMP_FILE" ]]; then
    rm -f "$TMP_FILE"
  fi
}
trap cleanup EXIT

usage() {
  cat >&2 <<EOF
Usage: ${0##*/} <version>

Set a new release version (X.Y.Z) across the xcconfig and the plugin binding.

Arguments:
  version   New semantic version, e.g. 4.15.0 (a leading "v" is accepted).

Example:
  ${0##*/} 4.15.0
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

# update_file <file> <locator-regex> <sed-substitution> <description>
update_file() {
  local file="$1" locator="$2" substitution="$3" description="$4"

  [[ -f "$file" ]] || die "file not found: ${file}"
  grep -Eq "$locator" "$file" \
    || die "could not find ${description} in ${file} (pattern: ${locator})"

  TMP_FILE="$(mktemp)"
  sed -E "$substitution" "$file" >"$TMP_FILE"
  cat "$TMP_FILE" >"$file"
  rm -f "$TMP_FILE"
  TMP_FILE=""

  echo "  ✓ ${description}"
}

main() {
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  [[ $# -eq 1 ]] || { usage; die "exactly one argument (the new version) is required"; }

  # Accept an optional leading "v", then validate strict semver X.Y.Z.
  local version="${1#v}"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || die "invalid version '${1}'; expected X.Y.Z (e.g. 4.15.0)"

  echo "Setting version to ${version}"

  # xcconfig: MARKETING_VERSION=X.Y.Z
  update_file "$XCCONFIG" \
    "^MARKETING_VERSION[[:space:]]*=" \
    "s/^(MARKETING_VERSION[[:space:]]*=[[:space:]]*).*/\1${version}/" \
    "xcconfig MARKETING_VERSION"

  # MUXSDKPlayerBinding.m: static NSString *const MUXSDKPluginVersion = @"X.Y.Z";
  update_file "$BINDING" \
    "MUXSDKPluginVersion[[:space:]]*=[[:space:]]*@\"" \
    "s/(MUXSDKPluginVersion[[:space:]]*=[[:space:]]*@\")[^\"]*\"/\1${version}\"/" \
    "MUXSDKPluginVersion constant"

  echo
  echo "Done. Review the changes with 'git diff' before committing."
}

main "$@"
