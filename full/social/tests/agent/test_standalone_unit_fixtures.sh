#!/usr/bin/env bash
# Isolated Social unit-fixture compile. Not a real UIKit/Accounts identity gate.
set -euo pipefail

die() {
    printf 'SOCIAL_STANDALONE_UNIT_FIXTURE_REFUSING: %s\n' "$*" >&2
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

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/social-standalone-unit-fixture.XXXXXX") \
    || die 'cannot create fixture directory'
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

run_dylib_bin() {
    local dir=$1
    local bin=$2
    LD_LIBRARY_PATH="$dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    DYLD_LIBRARY_PATH="$dir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
        "$bin"
}

require_fixture_marker() {
    python3 -c 'import sys; data=open(sys.argv[1],"rb").read(); sys.exit(0 if b"standalone-unit-fixture-only" in data else 1)' \
        "$1" \
        || die 'fixture dylib lacks standalone-unit-fixture-only marker'
}

printf 'SOCIAL_STANDALONE_UNIT_FIXTURE_COMPILE flag=SOCIAL_STANDALONE_TEST_FIXTURES\n'

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -D SOCIAL_STANDALONE_TEST_FIXTURES \
    -module-name Social \
    -emit-module-path "$STAGE/Social.swiftmodule" \
    -o "$STAGE/libSocial.dylib" \
    "${SOURCE_PATHS[@]}"
test -s "$STAGE/libSocial.dylib" || die 'fixture libSocial.dylib was not produced'
mkdir -p "$STAGE/production"
require_fixture_marker "$STAGE/libSocial.dylib"

swiftc -warnings-as-errors -parse-as-library -I "$STAGE" \
    -D SOCIAL_STANDALONE_TEST_FIXTURES \
    "$SCRIPT_DIR/SocialFallbackIdentityNegative.swift" \
    "$STAGE/libSocial.dylib" \
    -emit-library -emit-module -module-name SocialFallbackIdentityNegative \
    -o "$STAGE/libSocialFallbackIdentityNegative.dylib"
printf 'SOCIAL_STANDALONE_UNIT_FIXTURE_FALLBACKS_OK\n'

swiftc -warnings-as-errors -I "$STAGE" \
    -D SOCIAL_STANDALONE_TEST_FIXTURES \
    "$SCRIPT_DIR/SocialRuntime.swift" \
    "$STAGE/libSocial.dylib" \
    -o "$STAGE/guest-runtime"
runtime_output=$(run_dylib_bin "$STAGE" "$STAGE/guest-runtime")
printf '%s\n' "$runtime_output"
printf '%s\n' "$runtime_output" | grep -Fqx -- 'SOCIAL_DYLIB_KIND=standalone-unit-fixture-only' \
    || die 'runtime did not label the fixture dylib'
printf '%s\n' "$runtime_output" | grep -Fqx -- 'SOCIAL_STANDALONE_UNIT_FIXTURE_ONLY' \
    || die 'runtime did not emit SOCIAL_STANDALONE_UNIT_FIXTURE_ONLY'
printf '%s\n' "$runtime_output" | grep -Fqx -- 'SOCIAL_AGENT_RUNTIME_OK' \
    || die 'runtime did not emit SOCIAL_AGENT_RUNTIME_OK'

swiftc -warnings-as-errors -I "$STAGE" \
    -D SOCIAL_STANDALONE_TEST_FIXTURES \
    "$SCRIPT_DIR/SocialMultipartHardening.swift" \
    "$STAGE/libSocial.dylib" \
    -o "$STAGE/multipart-hardening"
multipart_output=$(run_dylib_bin "$STAGE" "$STAGE/multipart-hardening")
printf '%s\n' "$multipart_output"
printf '%s\n' "$multipart_output" | grep -Fqx -- 'SOCIAL_MULTIPART_HARDENING_OK' \
    || die 'multipart hardening probe failed'

production_status=0
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    -emit-module-path "$STAGE/production/Social.swiftmodule" \
    -o "$STAGE/production/libSocial.dylib" \
    "${SOURCE_PATHS[@]}" \
    >"$STAGE/production-missing.log" 2>&1 || production_status=$?
if [ "$production_status" -eq 0 ]; then
    die 'ordinary production compile succeeded without UIKit/Accounts'
fi
if ! grep -Eq "canonical UIKit module|Accounts module|dependency blocker|integration blocker|'ACAccount' is deprecated|ACAccount.*deprecated" \
    "$STAGE/production-missing.log"
then
    die "production missing-dependency compile failed unexpectedly: $(cat "$STAGE/production-missing.log")"
fi
printf 'SOCIAL_PRODUCTION_MISSING_DEPENDENCY_BLOCKER_OK\n'

LOOKALIKE=$(mktemp -d "${TMPDIR:-/tmp}/social-unit-fixture-lookalike.XXXXXX") \
    || die 'cannot create lookalike directory'
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name OpenUIKit \
    -emit-module-path "$LOOKALIKE/OpenUIKit.swiftmodule" \
    -o "$LOOKALIKE/libOpenUIKit.dylib" \
    "$SCRIPT_DIR/staging/OpenUIKit.swift"
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UIKit \
    -I "$LOOKALIKE" \
    -emit-module-path "$LOOKALIKE/UIKit.swiftmodule" \
    -o "$LOOKALIKE/libUIKit.dylib" \
    "$SCRIPT_DIR/staging/UIKit.swift" \
    "$LOOKALIKE/libOpenUIKit.dylib"
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Accounts \
    -emit-module-path "$LOOKALIKE/Accounts.swiftmodule" \
    -o "$LOOKALIKE/libAccounts.dylib" \
    "$SCRIPT_DIR/staging/Accounts.swift"
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    -I "$LOOKALIKE" \
    -emit-module-path "$LOOKALIKE/Social.swiftmodule" \
    -o "$LOOKALIKE/libSocial.dylib" \
    "${SOURCE_PATHS[@]}" \
    "$LOOKALIKE/libUIKit.dylib" \
    "$LOOKALIKE/libAccounts.dylib" \
    "$LOOKALIKE/libOpenUIKit.dylib"
negative_status=0
swiftc -warnings-as-errors -parse-as-library -I "$LOOKALIKE" \
    "$SCRIPT_DIR/SocialFallbackIdentityNegative.swift" \
    "$LOOKALIKE/libSocial.dylib" \
    "$LOOKALIKE/libUIKit.dylib" \
    "$LOOKALIKE/libOpenUIKit.dylib" \
    "$LOOKALIKE/libAccounts.dylib" \
    -emit-library -emit-module -module-name SocialFallbackIdentityNegative \
    -o "$LOOKALIKE/libSocialFallbackIdentityNegative.dylib" \
    >"$LOOKALIKE/negative.log" 2>&1 || negative_status=$?
if [ "$negative_status" -eq 0 ]; then
    die 'lookalike UIKit/Accounts compile still published Social-owned fallbacks'
fi
printf 'SOCIAL_UNIT_FIXTURE_LOOKALIKE_NO_SOCIAL_OWNED_DEPENDENCY_TYPES\n'

swiftc -warnings-as-errors -I "$LOOKALIKE" \
    "$SCRIPT_DIR/SocialPlatformConsumer.swift" \
    "$LOOKALIKE/libSocial.dylib" \
    "$LOOKALIKE/libUIKit.dylib" \
    "$LOOKALIKE/libOpenUIKit.dylib" \
    "$LOOKALIKE/libAccounts.dylib" \
    -o "$LOOKALIKE/social-lookalike-consumer"
lookalike_output=$(run_dylib_bin "$LOOKALIKE" "$LOOKALIKE/social-lookalike-consumer")
printf '%s\n' "$lookalike_output"
printf '%s\n' "$lookalike_output" | grep -Fqx -- 'SOCIAL_UNIT_FIXTURE_LOOKALIKE_CONSUMER_OK' \
    || die 'lookalike consumer failed'
printf '%s\n' "$lookalike_output" | grep -Fqx -- 'SOCIAL_UNIT_FIXTURE_LOOKALIKE_NOT_PLATFORM_IDENTITY' \
    || die 'lookalike consumer must not claim platform identity'
printf 'SOCIAL_UNIT_FIXTURE_LOOKALIKE_NOT_PLATFORM_IDENTITY\n'
rm -rf -- "$LOOKALIKE"

uikit_only=$(mktemp -d "${TMPDIR:-/tmp}/social-uikit-only.XXXXXX") \
    || die 'cannot create UIKit-only directory'
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name OpenUIKit \
    -emit-module-path "$uikit_only/OpenUIKit.swiftmodule" \
    -o "$uikit_only/libOpenUIKit.dylib" \
    "$SCRIPT_DIR/staging/OpenUIKit.swift"
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name UIKit \
    -I "$uikit_only" \
    -emit-module-path "$uikit_only/UIKit.swiftmodule" \
    -o "$uikit_only/libUIKit.dylib" \
    "$SCRIPT_DIR/staging/UIKit.swift" \
    "$uikit_only/libOpenUIKit.dylib"
accounts_status=0
swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name Social \
    -I "$uikit_only" \
    -emit-module-path "$uikit_only/Social.swiftmodule" \
    -o "$uikit_only/libSocial.dylib" \
    "${SOURCE_PATHS[@]}" \
    "$uikit_only/libUIKit.dylib" \
    "$uikit_only/libOpenUIKit.dylib" \
    >"$uikit_only/accounts-missing.log" 2>&1 || accounts_status=$?
if [ "$accounts_status" -eq 0 ]; then
    host_accounts_negative=0
    swiftc -warnings-as-errors -parse-as-library -I "$uikit_only" \
        "$SCRIPT_DIR/SocialFallbackIdentityNegative.swift" \
        "$uikit_only/libSocial.dylib" \
        "$uikit_only/libUIKit.dylib" \
        "$uikit_only/libOpenUIKit.dylib" \
        -emit-library -emit-module -module-name SocialFallbackIdentityNegative \
        -o "$uikit_only/libSocialFallbackIdentityNegative.dylib" \
        >"$uikit_only/host-accounts-negative.log" 2>&1 || host_accounts_negative=$?
    if [ "$host_accounts_negative" -eq 0 ]; then
        die 'host Accounts compile published Social-owned UIKit/Accounts types'
    fi
    printf 'SOCIAL_PRODUCTION_HOST_ACCOUNTS_AVAILABLE\n'
else
    if ! grep -Eq 'Accounts module|integration blocker|Social.ACAccount' \
        "$uikit_only/accounts-missing.log"
    then
        die "UIKit-without-Accounts compile failed unexpectedly: $(cat "$uikit_only/accounts-missing.log")"
    fi
    printf 'SOCIAL_PRODUCTION_MISSING_ACCOUNTS_BLOCKER_OK\n'
fi
rm -rf -- "$uikit_only"

printf 'SOCIAL_STANDALONE_UNIT_FIXTURE_GATE_OK\n'
