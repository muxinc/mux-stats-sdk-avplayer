#!/usr/bin/env bash
# Offline tests for scripts/set-version.sh.
# Runs against fixture copies in a temp REPO_ROOT, never the real files.
set -uo pipefail

REPO_ROOT_REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
readonly REPO_ROOT_REAL WORK
readonly SCRIPT="$REPO_ROOT_REAL/scripts/set-version.sh"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

# Build a fixture repo at $1 with version $2 in both files (+ an unrelated
# MUXSDKPluginVersion *use* that must NOT be rewritten).
make_repo() {
    local root="$1" version="$2"
    mkdir -p "$root/scripts" "$root/Sources/MUXSDKStats"
    printf 'MARKETING_VERSION=%s\n' "$version" > "$root/scripts/MUXSDKStatsFramework.xcconfig"
    cat > "$root/Sources/MUXSDKStats/MUXSDKPlayerBinding.m" <<EOF
static NSString *const MUXSDKPluginVersion = @"${version}";

- (void)example {
    [playerData setPlayerMuxPluginVersion:MUXSDKPluginVersion];
}
EOF
}

check() {
    local name="$1" cond="$2"
    if eval "$cond"; then
        pass=$((pass + 1)); printf '  PASS  %s\n' "$name"
    else
        fail=$((fail + 1)); printf '  FAIL  %s\n' "$name"
    fi
}

echo "Testing scripts/set-version.sh (offline)"

# 1. Happy path: both files bumped, unrelated usage line untouched.
repo="$WORK/r1"; make_repo "$repo" "0.0.0"
REPO_ROOT="$repo" bash "$SCRIPT" 4.15.0 >/dev/null
check "happy: MARKETING_VERSION bumped" \
    "grep -q '^MARKETING_VERSION=4.15.0$' '$repo/scripts/MUXSDKStatsFramework.xcconfig'"
check "happy: MUXSDKPluginVersion bumped" \
    "grep -q 'MUXSDKPluginVersion = @\"4.15.0\";' '$repo/Sources/MUXSDKStats/MUXSDKPlayerBinding.m'"
check "happy: usage line left intact" \
    "grep -q 'setPlayerMuxPluginVersion:MUXSDKPluginVersion' '$repo/Sources/MUXSDKStats/MUXSDKPlayerBinding.m'"
check "happy: no stray 0.0.0 left" \
    "! grep -rq '0.0.0' '$repo'"

# 2. Leading 'v' accepted.
repo="$WORK/r2"; make_repo "$repo" "0.0.0"
REPO_ROOT="$repo" bash "$SCRIPT" v4.16.0 >/dev/null
check "leading v: strips to 4.16.0" \
    "grep -q '^MARKETING_VERSION=4.16.0$' '$repo/scripts/MUXSDKStatsFramework.xcconfig'"

# 3. Idempotent re-run.
REPO_ROOT="$repo" bash "$SCRIPT" 4.16.0 >/dev/null
check "idempotent: re-run keeps 4.16.0" \
    "grep -q 'MUXSDKPluginVersion = @\"4.16.0\";' '$repo/Sources/MUXSDKStats/MUXSDKPlayerBinding.m'"

# 4. Invalid version rejected (and nothing changed).
repo="$WORK/r4"; make_repo "$repo" "0.0.0"
REPO_ROOT="$repo" bash "$SCRIPT" 4.15 >/dev/null 2>&1
check "invalid version: exits non-zero" "[[ $? -ne 0 ]]"
check "invalid version: leaves files unchanged" \
    "grep -q '^MARKETING_VERSION=0.0.0$' '$repo/scripts/MUXSDKStatsFramework.xcconfig'"

# 5. Missing argument rejected.
REPO_ROOT="$WORK/r4" bash "$SCRIPT" >/dev/null 2>&1
check "missing arg: exits non-zero" "[[ $? -ne 0 ]]"

# 6. --help exits 0.
REPO_ROOT="$WORK/r4" bash "$SCRIPT" --help >/dev/null 2>&1
check "--help: exits 0" "[[ $? -eq 0 ]]"

# 7. Locator missing -> fails loudly.
repo="$WORK/r7"; make_repo "$repo" "0.0.0"
: > "$repo/scripts/MUXSDKStatsFramework.xcconfig" # wipe MARKETING_VERSION line
REPO_ROOT="$repo" bash "$SCRIPT" 4.15.0 >/dev/null 2>&1
check "missing locator: exits non-zero" "[[ $? -ne 0 ]]"

echo
echo "Results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
