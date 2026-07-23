#!/usr/bin/env bash
# Offline regression tests for scripts/create-tagged-release.sh.
# Uses the shared fake `gh`; no network or credentials are required.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
readonly REPO_ROOT WORK
readonly SCRIPT="$REPO_ROOT/scripts/create-tagged-release.sh"
readonly FAKE_BIN="$REPO_ROOT/scripts/tests/fake-bin"
readonly SHA="1111111111111111111111111111111111111111"
readonly OTHER_SHA="2222222222222222222222222222222222222222"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

new_state() {
    local file="$WORK/state.$RANDOM"
    : > "$file"
    [[ -n "${1:-}" ]] && printf '%s\n' "$@" >> "$file"
    echo "$file"
}

run_case() {
    local name="$1" expect="$2" needle="$3"; shift 4
    local out rc ok=1
    out="$(env "$@" \
        PATH="$FAKE_BIN:$PATH" \
        bash "$SCRIPT" 2>&1)"
    rc=$?

    if [[ "$expect" == "ok" && $rc -ne 0 ]]; then ok=0; fi
    if [[ "$expect" == "err" && $rc -eq 0 ]]; then ok=0; fi
    if [[ -n "$needle" ]] && ! grep -qiF "$needle" <<<"$out"; then ok=0; fi

    if [[ $ok -eq 1 ]]; then
        pass=$((pass + 1)); printf '  PASS  %s\n' "$name"
    else
        fail=$((fail + 1))
        printf '  FAIL  %s (rc=%d, expected=%s, needle=%q)\n' \
            "$name" "$rc" "$expect" "$needle"
        awk '{ print "        | " $0 }' <<<"$out"
    fi
}

set_common_env() {
    local state="$1"
    envs=( \
        "TAG=v9.9.9" \
        "SHA=$SHA" \
        "REPO=muxinc/mux-stats-sdk-avplayer" \
        "PR_BODY=Release notes" \
        "GH_TOKEN=token" \
        "MOCK_GH_STATE=$state" \
        "MOCK_GH_LOG=$state.log" \
    )
}

echo "Testing scripts/create-tagged-release.sh (offline)"

# 1. Fresh tag and release: the path that failed during v4.15.0.
st="$(new_state "TAG=v9.9.9")"
set_common_env "$st"
run_case "fresh tag: creates tag and draft" ok "Created draft release" -- "${envs[@]}"
if grep -q "api repos/.*/git/refs" "$st.log" \
    && grep -q "release create" "$st.log"; then
    pass=$((pass + 1)); echo "  PASS  fresh tag: called tag + release creation"
else
    fail=$((fail + 1)); echo "  FAIL  fresh tag: expected tag + release creation"
fi

# 2. Idempotent rerun at the same SHA with an existing draft.
st="$(new_state "TAG=v9.9.9" "TAG_SHA=$SHA" "EXISTS=true" "DRAFT=true")"
set_common_env "$st"
run_case "same tag and draft: continues" ok "already exists" -- "${envs[@]}"
if ! grep -q "api repos/.*/git/refs -f" "$st.log" \
    && ! grep -q "release create" "$st.log"; then
    pass=$((pass + 1)); echo "  PASS  idempotent rerun: created nothing"
else
    fail=$((fail + 1)); echo "  FAIL  idempotent rerun: should create nothing"
fi

# 3. A prefix match must not be mistaken for the exact tag.
st="$(new_state "TAG=v9.9.9" "PARTIAL_TAG_SHA=$OTHER_SHA")"
set_common_env "$st"
run_case "partial tag match: creates exact tag" ok "Created tag" -- "${envs[@]}"

# 4. Existing exact tag at another SHA is a hard stop.
st="$(new_state "TAG=v9.9.9" "TAG_SHA=$OTHER_SHA")"
set_common_env "$st"
run_case "conflicting tag: refuses" err "points to" -- "${envs[@]}"

# 5. Published releases are never modified.
st="$(new_state "TAG=v9.9.9" "TAG_SHA=$SHA" "EXISTS=true" "DRAFT=false")"
set_common_env "$st"
run_case "published release: refuses" err "already exists and is published" -- "${envs[@]}"

# 6. Tag lookup API failures stay fatal instead of looking like a missing tag.
st="$(new_state "TAG=v9.9.9" "API_FAIL=true")"
set_common_env "$st"
run_case "tag API failure: refuses" err "simulated GitHub API failure" -- "${envs[@]}"

# 7. Release lookup failures stay fatal. A rerun can reuse the created tag.
st="$(new_state "TAG=v9.9.9" "RELEASE_LIST_FAIL=true")"
set_common_env "$st"
run_case "release API failure: refuses" err "simulated release list failure" -- "${envs[@]}"

# 8. Invalid input fails before contacting GitHub.
st="$(new_state)"
set_common_env "$st"
envs[0]="TAG=not-a-tag"
run_case "invalid tag: refuses" err "TAG must look like" -- "${envs[@]}"

echo
echo "Results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
