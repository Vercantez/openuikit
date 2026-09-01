#!/usr/bin/env bash
# Real Social integration gate. Consumes staged platform Foundation / UIKit /
# OpenUIKit / Accounts outputs from the repository or guest layout. Never
# compiles replacement dependency APIs from tests/agent/staging.
set -euo pipefail

die() {
    printf 'SOCIAL_REAL_INTEGRATION_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'

for stale in .build build scratch; do
    [ ! -e "$FRAMEWORK_ROOT/$stale" ] \
        || die "stale product directory exists: $stale"
done

command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'
command -v python3 >/dev/null 2>&1 || die 'python3 is unavailable'
unset ADDITIONAL_SWIFT_DRIVER_FLAGS || true

mapfile -t SOURCES < "$FRAMEWORK_ROOT/social_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

module_dir() {
    local name=$1
    local candidate
    for candidate in "$@"; do
        [ "$candidate" = "$name" ] && continue
        [ -n "$candidate" ] || continue
        if [ -d "$candidate/${name}.swiftmodule" ] || [ -f "$candidate/${name}.swiftmodule" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

dylib_in() {
    local dir=$1
    local name=$2
    local candidate
    for candidate in \
        "$dir/lib${name}.dylib" \
        "$dir/lib${name}.so" \
        "$dir/${name}.dylib"
    do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

FOUNDATION_DIR=""
if FOUNDATION_DIR=$(module_dir Foundation \
    "${SOCIAL_REAL_PLATFORM_ROOT:-}" \
    "${TRUE_IOS_PACKAGE:-}" \
    "${SOCIAL_PLATFORM_FOUNDATION:-}" \
    /usr/lib/swift/linux \
    /usr/lib/swift)
then
    printf 'SOCIAL_REAL_INTEGRATION_FOUNDATION_STAGED module=Foundation source=%s\n' \
        "$FOUNDATION_DIR"
else
    printf 'SOCIAL_REAL_INTEGRATION_BLOCKED dependency=Foundation reason=not-staged\n'
fi

UIKIT_SEARCH=(
    "${SOCIAL_REAL_PLATFORM_ROOT:-}"
    "${TRUE_IOS_PACKAGE:-}"
    "${SOCIAL_PLATFORM_UIKIT:-}"
    "${UIKIT_STAGE:-}"
    "${UIKIT:-}"
    /uikit
    "${HOME}/uikit"
    /workspace/uikit
)
UIKIT_DIR=""
OPENUIKIT_DIR=""
if UIKIT_DIR=$(module_dir UIKit "${UIKIT_SEARCH[@]}"); then
    OPENUIKIT_DIR=$(module_dir OpenUIKit "${UIKIT_SEARCH[@]}" "$UIKIT_DIR" || true)
    printf 'SOCIAL_REAL_INTEGRATION_UIKIT_STAGED module=UIKit source=%s\n' "$UIKIT_DIR"
    if [ -n "${OPENUIKIT_DIR:-}" ]; then
        printf 'SOCIAL_REAL_INTEGRATION_OPENUIKIT_STAGED module=OpenUIKit source=%s\n' \
            "$OPENUIKIT_DIR"
    fi
else
    printf 'SOCIAL_REAL_INTEGRATION_BLOCKED dependency=UIKit reason=canonical-UIKit/OpenUIKit-implementation-not-staged-in-this-workspace\n'
fi

ACCOUNTS_SEARCH=(
    "${SOCIAL_REAL_PLATFORM_ROOT:-}"
    "${TRUE_IOS_PACKAGE:-}"
    "${SOCIAL_PLATFORM_ACCOUNTS:-}"
    "${ACCOUNTS_STAGE:-}"
    /uikit
    "${HOME}/uikit"
)
ACCOUNTS_DIR=""
if ACCOUNTS_DIR=$(module_dir Accounts "${ACCOUNTS_SEARCH[@]}"); then
    printf 'SOCIAL_REAL_INTEGRATION_ACCOUNTS_STAGED module=Accounts source=%s\n' \
        "$ACCOUNTS_DIR"
else
    printf 'SOCIAL_REAL_INTEGRATION_BLOCKED dependency=Accounts reason=not-staged-in-shared-platform\n'
fi

if [ -z "${UIKIT_DIR:-}" ] || [ -z "${ACCOUNTS_DIR:-}" ]; then
    printf 'SOCIAL_REAL_INTEGRATION_DEFERRED\n'
    printf 'SOCIAL_REAL_INTEGRATION_GATE_INCOMPLETE\n'
    exit 0
fi

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/social-real-integration.XXXXXX") \
    || die 'cannot create integration directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

INCLUDE=(-I "$UIKIT_DIR" -I "$ACCOUNTS_DIR")
LINK=()
if [ -n "${OPENUIKIT_DIR:-}" ]; then
    INCLUDE+=(-I "$OPENUIKIT_DIR")
fi
if UIKIT_DYLIB=$(dylib_in "$UIKIT_DIR" UIKit); then
    LINK+=("$UIKIT_DYLIB")
fi
if ACCOUNTS_DYLIB=$(dylib_in "$ACCOUNTS_DIR" Accounts); then
    LINK+=("$ACCOUNTS_DYLIB")
fi
if [ -n "${OPENUIKIT_DIR:-}" ] && OPENUIKIT_DYLIB=$(dylib_in "$OPENUIKIT_DIR" OpenUIKit); then
    LINK+=("$OPENUIKIT_DYLIB")
fi

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    "${INCLUDE[@]}" \
    -emit-module-path "$STAGE/Social.swiftmodule" \
    -o "$STAGE/libSocial.dylib" \
    "${SOURCE_PATHS[@]}" \
    "${LINK[@]}"
test -s "$STAGE/libSocial.dylib" || die 'production libSocial.dylib was not produced'
if strings "$STAGE/libSocial.dylib" | grep -Fq 'standalone-unit-fixture-only'; then
    die 'real-integration dylib carries standalone-unit-fixture-only'
fi

negative_status=0
swiftc -warnings-as-errors -parse-as-library \
    "${INCLUDE[@]}" -I "$STAGE" \
    "$SCRIPT_DIR/SocialFallbackIdentityNegative.swift" \
    "$STAGE/libSocial.dylib" \
    "${LINK[@]}" \
    -emit-library -emit-module -module-name SocialFallbackIdentityNegative \
    -o "$STAGE/libSocialFallbackIdentityNegative.dylib" \
    >"$STAGE/negative.log" 2>&1 || negative_status=$?
if [ "$negative_status" -eq 0 ]; then
    die 'real integration Social published Social-owned UIKit/Accounts types'
fi
if ! grep -Eq 'UIView|UITextViewDelegate|ACAccount' "$STAGE/negative.log"; then
    die "real-integration negative probe failed unexpectedly: $(cat "$STAGE/negative.log")"
fi
printf 'SOCIAL_REAL_INTEGRATION_INTERFACE_OK\n'

if command -v swift-symbolgraph-extract >/dev/null 2>&1; then
    mkdir -p "$STAGE/symbols"
    TARGET=$(swiftc -print-target-info | python3 -c 'import json,sys; print(json.load(sys.stdin)["target"]["triple"])')
    extract_status=0
    swift-symbolgraph-extract \
        -target "$TARGET" \
        -module-name Social \
        "${INCLUDE[@]}" -I "$STAGE" \
        -output-dir "$STAGE/symbols" \
        -pretty-print \
        >"$STAGE/symbolgraph.log" 2>&1 || extract_status=$?
    if [ "$extract_status" -ne 0 ]; then
        die "symbol graph extract failed: $(cat "$STAGE/symbolgraph.log")"
    fi
    if grep -E 'Social\.(UIView|UIViewController|UIImage|UITextView|UITextViewDelegate|ACAccount)' \
        "$STAGE/symbols"/*.json >/dev/null 2>&1; then
        die 'symbol graph contains Social-owned UIKit/Accounts types'
    fi
    printf 'SOCIAL_REAL_INTEGRATION_SYMBOLGRAPH_OK\n'
fi

swiftc -warnings-as-errors -parse-as-library \
    "${INCLUDE[@]}" -I "$STAGE" \
    "$SCRIPT_DIR/SocialUITextViewDelegateConformance.swift" \
    "$STAGE/libSocial.dylib" \
    "${LINK[@]}" \
    -emit-library -emit-module \
    -module-name SocialUITextViewDelegateConformance \
    -o "$STAGE/libSocialUITextViewDelegateConformance.dylib"
printf 'SOCIAL_REAL_INTEGRATION_CONFORMANCE_OK\n'

swiftc -warnings-as-errors -parse-as-library \
    "${INCLUDE[@]}" -I "$STAGE" \
    "$SCRIPT_DIR/SocialRealIntegrationClient.swift" \
    "$STAGE/libSocial.dylib" \
    "${LINK[@]}" \
    -emit-library -emit-module \
    -module-name SocialRealIntegrationClient \
    -o "$STAGE/libSocialRealIntegrationClient.dylib"
printf 'SOCIAL_REAL_INTEGRATION_CLIENT_OK\n'

LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    python3 - <<'PY' "$STAGE/libSocial.dylib"
import ctypes, sys
ctypes.CDLL(sys.argv[1])
print("SOCIAL_REAL_INTEGRATION_DYLIB_LOADED")
PY

printf 'SOCIAL_REAL_INTEGRATION_OK\n'
printf 'SOCIAL_REAL_INTEGRATION_GATE_OK\n'
