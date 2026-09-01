#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'SOCIAL_PLATFORM_IDENTITY_GATE_REFUSING: %s\n' "$*" >&2
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

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/social-platform-identity.XXXXXX") \
    || die 'cannot create staging directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

mapfile -t SOURCES < "$FRAMEWORK_ROOT/social_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

printf 'SOCIAL_PLATFORM_FOUNDATION_STAGED module=Foundation source=toolchain\n'

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name OpenUIKit \
    -emit-module-path "$STAGE/OpenUIKit.swiftmodule" \
    -o "$STAGE/libOpenUIKit.dylib" \
    "$SCRIPT_DIR/staging/OpenUIKit.swift"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UIKit \
    -I "$STAGE" \
    -emit-module-path "$STAGE/UIKit.swiftmodule" \
    -o "$STAGE/libUIKit.dylib" \
    "$SCRIPT_DIR/staging/UIKit.swift" \
    "$STAGE/libOpenUIKit.dylib"

printf 'SOCIAL_PLATFORM_UIKIT_STAGED module=UIKit implementation=OpenUIKit\n'

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Accounts \
    -emit-module-path "$STAGE/Accounts.swiftmodule" \
    -o "$STAGE/libAccounts.dylib" \
    "$SCRIPT_DIR/staging/Accounts.swift"

printf 'SOCIAL_PLATFORM_ACCOUNTS_STAGED module=Accounts source=tests/agent/staging/Accounts.swift\n'

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    -I "$STAGE" \
    -emit-module-path "$STAGE/Social.swiftmodule" \
    -o "$STAGE/libSocial.dylib" \
    "${SOURCE_PATHS[@]}" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libAccounts.dylib" \
    "$STAGE/libOpenUIKit.dylib"
test -s "$STAGE/libSocial.dylib" || die 'production libSocial.dylib was not produced'

negative_status=0
swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
    "$SCRIPT_DIR/SocialFallbackIdentityNegative.swift" \
    "$STAGE/libSocial.dylib" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libOpenUIKit.dylib" \
    "$STAGE/libAccounts.dylib" \
    -emit-library -emit-module -module-name SocialFallbackIdentityNegative \
    -o "$STAGE/libSocialFallbackIdentityNegative.dylib" \
    >"$STAGE/negative.log" 2>&1 || negative_status=$?
if [ "$negative_status" -eq 0 ]; then
    die 'production Social compiled Social.UIView/ACAccount fallback identities'
fi
if ! grep -Eq 'UIView|UITextViewDelegate|ACAccount' "$STAGE/negative.log"; then
    die "production negative probe failed for an unexpected reason: $(cat "$STAGE/negative.log")"
fi
printf 'SOCIAL_PLATFORM_INTERFACE_OK\n'

if command -v swift-symbolgraph-extract >/dev/null 2>&1; then
    mkdir -p "$STAGE/symbols"
    TARGET=$(swiftc -print-target-info | python3 -c 'import json,sys; print(json.load(sys.stdin)["target"]["triple"])')
    extract_status=0
    swift-symbolgraph-extract \
        -target "$TARGET" \
        -module-name Social \
        -I "$STAGE" \
        -output-dir "$STAGE/symbols" \
        -pretty-print \
        >"$STAGE/symbolgraph.log" 2>&1 || extract_status=$?
    if [ "$extract_status" -ne 0 ]; then
        die "symbol graph extract failed: $(cat "$STAGE/symbolgraph.log")"
    fi
    if grep -E 'Social\.(UIView|UIViewController|UIImage|UITextView|UITextViewDelegate|ACAccount)' \
        "$STAGE/symbols"/*.json >/dev/null 2>&1; then
        die 'symbol graph contains Social UIKit/Accounts identity types'
    fi
    printf 'SOCIAL_PLATFORM_SYMBOLGRAPH_OK\n'
fi

swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
    "$SCRIPT_DIR/SocialUITextViewDelegateConformance.swift" \
    "$STAGE/libSocial.dylib" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libOpenUIKit.dylib" \
    "$STAGE/libAccounts.dylib" \
    -emit-library -emit-module \
    -module-name SocialUITextViewDelegateConformance \
    -o "$STAGE/libSocialUITextViewDelegateConformance.dylib"
printf 'SOCIAL_PLATFORM_CONFORMANCE_OK\n'

swiftc -warnings-as-errors -I "$STAGE" \
    "$SCRIPT_DIR/SocialPlatformConsumer.swift" \
    "$STAGE/libSocial.dylib" \
    "$STAGE/libUIKit.dylib" \
    "$STAGE/libOpenUIKit.dylib" \
    "$STAGE/libAccounts.dylib" \
    -o "$STAGE/social-platform-consumer"

identity_output=$(
    LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        "$STAGE/social-platform-consumer"
)
printf '%s\n' "$identity_output"
printf '%s\n' "$identity_output" | grep -Fqx -- 'SOCIAL_PLATFORM_IDENTITY_OK' \
    || die 'platform consumer did not emit SOCIAL_PLATFORM_IDENTITY_OK'

STANDALONE=$(mktemp -d "${TMPDIR:-/tmp}/social-standalone-interface.XXXXXX") \
    || die 'cannot create standalone interface directory'
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    -emit-module-path "$STANDALONE/Social.swiftmodule" \
    -o "$STANDALONE/libSocial.dylib" \
    "${SOURCE_PATHS[@]}"
test -s "$STANDALONE/libSocial.dylib" || die 'standalone libSocial.dylib missing'

standalone_negative_status=0
swiftc -warnings-as-errors -parse-as-library -I "$STANDALONE" \
    "$SCRIPT_DIR/SocialFallbackIdentityNegative.swift" \
    "$STANDALONE/libSocial.dylib" \
    -emit-library -emit-module -module-name SocialFallbackIdentityNegative \
    -o "$STANDALONE/libSocialFallbackIdentityNegative.dylib" \
    >"$STANDALONE/negative.log" 2>&1 || standalone_negative_status=$?
if [ "$standalone_negative_status" -ne 0 ]; then
    die "standalone Social lost isolated fallback identities: $(cat "$STANDALONE/negative.log")"
fi
printf 'SOCIAL_PLATFORM_DIFF_OK standalone-has-fallbacks production-has-canonical-uikit-accounts\n'
rm -rf -- "$STANDALONE"

printf 'SOCIAL_PLATFORM_IDENTITY_GATE_OK\n'
