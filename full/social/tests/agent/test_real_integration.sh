#!/usr/bin/env bash
# Real Social integration gate. Consumes only operator-provided canonical
# platform products for Foundation, UIKit/OpenUIKit, and Accounts. Never
# discovers HOME, /uikit, toolchain Swift, or tests/agent/staging lookalikes.
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

SOURCE_PATHS=()
while IFS= read -r relative || [ -n "$relative" ]; do
    [ -z "$relative" ] && continue
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done < "$FRAMEWORK_ROOT/social_guest_sources.txt"

explicit_search_dirs() {
    printf '%s\n' \
        "${SOCIAL_PLATFORM_FOUNDATION:-}" \
        "${SOCIAL_PLATFORM_UIKIT:-}" \
        "${SOCIAL_PLATFORM_OPENUIKIT:-}" \
        "${SOCIAL_PLATFORM_ACCOUNTS:-}" \
        "${SOCIAL_REAL_PLATFORM_ROOT:-}"
}

is_test_owned_dir() {
    local dir=$1
    local resolved
    resolved=$(CDPATH= cd -- "$dir" 2>/dev/null && pwd -P) || return 1
    case "$resolved" in
        "$FRAMEWORK_ROOT/tests"|"$FRAMEWORK_ROOT/tests"/*)
            return 0
            ;;
    esac
    return 1
}

module_dir_explicit() {
    local name=$1
    local candidate
    while IFS= read -r candidate || [ -n "$candidate" ]; do
        [ -n "$candidate" ] || continue
        if [ -d "$candidate/${name}.swiftmodule" ] || [ -f "$candidate/${name}.swiftmodule" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
        if [ -d "$candidate/$name/${name}.swiftmodule" ] || [ -f "$candidate/$name/${name}.swiftmodule" ]; then
            printf '%s\n' "$candidate/$name"
            return 0
        fi
    done
    return 1
}

accept_canonical_or_block() {
    local name=$1
    local staged_tag=$2
    local missing_reason=$3
    local dir=$4
    if [ -z "$dir" ]; then
        printf 'SOCIAL_REAL_INTEGRATION_BLOCKED dependency=%s reason=%s\n' \
            "$name" "$missing_reason"
        blocked=1
        return 1
    fi
    if is_test_owned_dir "$dir"; then
        printf 'SOCIAL_REAL_INTEGRATION_BLOCKED dependency=%s reason=test-owned-identity-refused\n' \
            "$name"
        blocked=1
        return 1
    fi
    printf 'SOCIAL_REAL_INTEGRATION_%s_STAGED module=%s source=%s\n' \
        "$staged_tag" "$name" "$dir"
    return 0
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

blocked=0

FOUNDATION_DIR=""
FOUNDATION_DIR=$(explicit_search_dirs | module_dir_explicit Foundation) || true
accept_canonical_or_block Foundation FOUNDATION \
    explicit-canonical-product-not-provided "$FOUNDATION_DIR" \
    || FOUNDATION_DIR=""

UIKIT_DIR=""
UIKIT_DIR=$(explicit_search_dirs | module_dir_explicit UIKit) || true
accept_canonical_or_block UIKit UIKIT \
    explicit-canonical-product-not-provided "$UIKIT_DIR" \
    || UIKIT_DIR=""

OPENUIKIT_DIR=""
OPENUIKIT_DIR=$(explicit_search_dirs | module_dir_explicit OpenUIKit) || true
accept_canonical_or_block OpenUIKit OPENUIKIT \
    explicit-canonical-product-not-provided "$OPENUIKIT_DIR" \
    || OPENUIKIT_DIR=""

ACCOUNTS_DIR=""
ACCOUNTS_DIR=$(explicit_search_dirs | module_dir_explicit Accounts) || true
accept_canonical_or_block Accounts ACCOUNTS \
    not-staged-in-shared-platform "$ACCOUNTS_DIR" \
    || ACCOUNTS_DIR=""

if [ "$blocked" -ne 0 ]; then
    printf 'SOCIAL_REAL_INTEGRATION_DEFERRED\n'
    exit 0
fi

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/social-real-integration.XXXXXX") \
    || die 'cannot create integration directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

INCLUDE=(-I "$FOUNDATION_DIR" -I "$UIKIT_DIR" -I "$OPENUIKIT_DIR" -I "$ACCOUNTS_DIR")
LINK=()
if FOUNDATION_DYLIB=$(dylib_in "$FOUNDATION_DIR" Foundation); then
    LINK+=("$FOUNDATION_DYLIB")
fi
if UIKIT_DYLIB=$(dylib_in "$UIKIT_DIR" UIKit); then
    LINK+=("$UIKIT_DYLIB")
fi
if OPENUIKIT_DYLIB=$(dylib_in "$OPENUIKIT_DIR" OpenUIKit); then
    LINK+=("$OPENUIKIT_DYLIB")
fi
if ACCOUNTS_DYLIB=$(dylib_in "$ACCOUNTS_DIR" Accounts); then
    LINK+=("$ACCOUNTS_DYLIB")
fi

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    "${INCLUDE[@]}" \
    -emit-module-path "$STAGE/Social.swiftmodule" \
    -o "$STAGE/libSocial.dylib" \
    "${SOURCE_PATHS[@]}" \
    "${LINK[@]}"
test -s "$STAGE/libSocial.dylib" || die 'production libSocial.dylib was not produced'
if python3 -c 'import sys; data=open(sys.argv[1],"rb").read(); sys.exit(0 if b"standalone-unit-fixture-only" in data else 1)' \
    "$STAGE/libSocial.dylib"
then
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

compile_corpus_client() {
    local source=$1
    local module=$2
    swiftc -warnings-as-errors -parse-as-library \
        "${INCLUDE[@]}" -I "$STAGE" \
        "$source" \
        "$STAGE/libSocial.dylib" \
        "${LINK[@]}" \
        -emit-library -emit-module \
        -module-name "$module" \
        -o "$STAGE/lib${module}.dylib"
}

compile_corpus_client "$SCRIPT_DIR/SocialFocusFirefoxClient.swift" SocialFocusClient
printf 'SOCIAL_REAL_INTEGRATION_FOCUS_CLIENT_OK\n'
compile_corpus_client "$SCRIPT_DIR/SocialFocusFirefoxClient.swift" SocialFirefoxClient
printf 'SOCIAL_REAL_INTEGRATION_FIREFOX_CLIENT_OK\n'
compile_corpus_client "$SCRIPT_DIR/SocialDuckDuckGoClient.swift" SocialDuckDuckGoClient
printf 'SOCIAL_REAL_INTEGRATION_DUCKDUCKGO_CLIENT_OK\n'
compile_corpus_client "$SCRIPT_DIR/SocialHomeAssistantClient.swift" SocialHomeAssistantClient
printf 'SOCIAL_REAL_INTEGRATION_HOMEASSISTANT_CLIENT_OK\n'
compile_corpus_client "$SCRIPT_DIR/SocialPocketCastsClient.swift" SocialPocketCastsClient
printf 'SOCIAL_REAL_INTEGRATION_POCKETCASTS_IMPORT_OK\n'
compile_corpus_client "$SCRIPT_DIR/SocialSimplenoteClient.swift" SocialSimplenoteClient
printf 'SOCIAL_REAL_INTEGRATION_SIMPLENOTE_IMPORT_OK\n'

LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
DYLD_LIBRARY_PATH="$STAGE${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    python3 - <<'PY' "$STAGE/libSocial.dylib"
import ctypes, sys
ctypes.CDLL(sys.argv[1])
print("SOCIAL_REAL_INTEGRATION_DYLIB_LOADED")
PY

printf 'SOCIAL_REAL_INTEGRATION_OK\n'
printf 'SOCIAL_REAL_INTEGRATION_GATE_OK\n'
