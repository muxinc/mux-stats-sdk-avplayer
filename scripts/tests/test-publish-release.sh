#!/usr/bin/env bash
# Offline tests for scripts/publish-release.sh.
# Uses a fake `gh` (scripts/tests/fake-bin/gh) and synthetic fixtures, so it
# makes no network calls and needs no credentials. Run: bash scripts/tests/test-publish-release.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
readonly REPO_ROOT WORK
readonly SCRIPT="$REPO_ROOT/scripts/publish-release.sh"
readonly FAKE_BIN="$REPO_ROOT/scripts/tests/fake-bin"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

# Build a fixture artifacts dir whose podspec checksum matches its zip.
make_fixtures() {
    local dir="$1" version="$2"
    mkdir -p "$dir"
    printf 'dummy-xcframework-zip-bytes' > "$dir/Cocoapods-Mux-Stats-AVPlayer.zip"
    local sum
    sum="$(shasum -a 256 "$dir/Cocoapods-Mux-Stats-AVPlayer.zip" | awk '{ print $1 }')"
    cat > "$dir/Mux-Stats-AVPlayer.podspec" <<EOF
Pod::Spec.new do |s|
  s.name    = 'Mux-Stats-AVPlayer'
  s.version = '${version}'
  s.source  = { :http => 'https://github.com/muxinc/mux-stats-sdk-avplayer/releases/download/v${version}/Cocoapods-Mux-Stats-AVPlayer.zip',
                :sha256 => '${sum}' }
end
EOF
}

# run_case <name> <expected: ok|err> <grep-needle-or-""> -- <env assignments...>
run_case() {
    local name="$1" expect="$2" needle="$3"; shift 4 # drop name expect needle "--"
    local out rc
    out="$(env "$@" \
        PATH="$FAKE_BIN:$PATH" \
        bash "$SCRIPT" 2>&1)"
    rc=$?

    local ok=1
    if [[ "$expect" == "ok" && $rc -ne 0 ]]; then ok=0; fi
    if [[ "$expect" == "err" && $rc -eq 0 ]]; then ok=0; fi
    if [[ -n "$needle" ]] && ! grep -qiF "$needle" <<<"$out"; then ok=0; fi

    if [[ $ok -eq 1 ]]; then
        pass=$((pass + 1)); printf '  PASS  %s\n' "$name"
    else
        fail=$((fail + 1))
        printf '  FAIL  %s (rc=%d, expected=%s, needle=%q)\n' "$name" "$rc" "$expect" "$needle"
        awk '{ print "        | " $0 }' <<<"$out"
    fi
}

# Fresh mock state file; optionally pre-seed an existing release.
new_state() {
    local file="$WORK/state.$RANDOM"
    : > "$file"
    [[ -n "${1:-}" ]] && printf '%s\n' "$@" >> "$file"
    echo "$file"
}

echo "Testing scripts/publish-release.sh (offline)"

# 1. Happy path: no release yet -> create draft + upload.
fx="$WORK/fx1"; make_fixtures "$fx" "9.9.9"; st="$(new_state "TAG=v9.9.9")"
run_case "happy path: creates draft and uploads" ok "Attached assets" -- \
    VERSION=v9.9.9 ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"
if grep -q "release create" "$st.log" && grep -q "release upload" "$st.log"; then
    pass=$((pass+1)); echo "  PASS  happy path: called release create + upload"
else
    fail=$((fail+1)); echo "  FAIL  happy path: expected create + upload in gh log"
fi

# 2. Draft already exists -> reuse (no create), still uploads.
fx="$WORK/fx2"; make_fixtures "$fx" "9.9.9"; st="$(new_state "EXISTS=true" "DRAFT=true" "TAG=v9.9.9")"
run_case "existing draft: reuses and uploads" ok "Using draft release" -- \
    VERSION=v9.9.9 ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"
if ! grep -q "release create" "$st.log" && grep -q "release upload" "$st.log"; then
    pass=$((pass+1)); echo "  PASS  existing draft: did NOT create, did upload"
else
    fail=$((fail+1)); echo "  FAIL  existing draft: should reuse (no create) but upload"
fi

# 3. Release already PUBLISHED -> refuse.
fx="$WORK/fx3"; make_fixtures "$fx" "9.9.9"; st="$(new_state "EXISTS=true" "DRAFT=false" "TAG=v9.9.9")"
run_case "published release: refuses to modify" err "already published" -- \
    VERSION=v9.9.9 ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"

# 4. Tampered zip -> checksum mismatch.
fx="$WORK/fx4"; make_fixtures "$fx" "9.9.9"; printf 'tamper' >> "$fx/Cocoapods-Mux-Stats-AVPlayer.zip"
st="$(new_state)"
run_case "tampered zip: checksum mismatch fails" err "checksum" -- \
    VERSION=v9.9.9 ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"

# 5. Version mismatch -> fails before touching GitHub.
fx="$WORK/fx5"; make_fixtures "$fx" "9.9.9"; st="$(new_state)"
run_case "version mismatch: rejects podspec" err "version does not match" -- \
    VERSION=v1.2.3 ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"

# 6. Missing artifact -> fails.
fx="$WORK/fx6"; mkdir -p "$fx"; st="$(new_state)"
run_case "missing artifact: fails" err "Missing artifact" -- \
    VERSION=v9.9.9 ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"

# 7. Missing token -> fails.
fx="$WORK/fx7"; make_fixtures "$fx" "9.9.9"; st="$(new_state)"
run_case "missing token: fails" err "No GitHub token" -- \
    VERSION=v9.9.9 ARTIFACTS_DIR="$fx" GITHUB_TOKEN= GH_TOKEN= \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"

# 8. Bad version format -> fails.
fx="$WORK/fx8"; make_fixtures "$fx" "9.9.9"; st="$(new_state)"
run_case "bad version format: fails" err "must look like" -- \
    VERSION=not-a-version ARTIFACTS_DIR="$fx" GITHUB_TOKEN=tok \
    MOCK_GH_STATE="$st" MOCK_GH_LOG="$st.log"

echo
echo "Results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
