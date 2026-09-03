#!/usr/bin/env bash
# Explicit test-only compile of synthetic Foundation/UIKit lookalikes.
#
# This is not platform identity evidence. It never emits
# NOTIFICATIONCENTER_PLATFORM_STAGE_OK, NOTIFICATIONCENTER_PLATFORM_DYLIB_OK,
# or NOTIFICATIONCENTER_IDENTITY_PROBE_OK. Set NOTIFICATIONCENTER_UNIT_FIXTURE=1
# to run; otherwise skip.
set -euo pipefail

die() {
    printf 'NOTIFICATIONCENTER_UNIT_FIXTURE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework seed is not inside a Git worktree'
STAGE_SOURCES=$SCRIPT_DIR/platform-stage

if [ "${NOTIFICATIONCENTER_UNIT_FIXTURE:-}" != "1" ]; then
    printf 'NOTIFICATIONCENTER_UNIT_FIXTURE_SKIPPED set NOTIFICATIONCENTER_UNIT_FIXTURE=1 to compile lookalikes\n'
    printf 'NOTIFICATIONCENTER_UNIT_FIXTURE_NOT_PLATFORM_IDENTITY_EVIDENCE\n'
    exit 0
fi

command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'

TMP=$(mktemp -d "${TMPDIR:-/tmp}/notificationcenter-unit-fixture.XXXXXX") \
    || die 'cannot create unit-fixture directory'
cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT HUP INT TERM

STAGE=$TMP/lookalike-stage
mkdir -p "$STAGE"
printf 'NOTIFICATIONCENTER_UNIT_FIXTURE_NOT_PLATFORM_IDENTITY_EVIDENCE\n' \
    > "$STAGE/NOTIFICATIONCENTER_UNIT_FIXTURE"

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -D NOTIFICATIONCENTER_UNIT_FIXTURE \
    -module-name Foundation \
    -emit-module-path "$STAGE/Foundation.swiftmodule" \
    -o "$STAGE/libFoundation.dylib" \
    "$STAGE_SOURCES/StagedFoundation.swift"
test -s "$STAGE/libFoundation.dylib" || die 'unit-fixture libFoundation.dylib missing'

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -D NOTIFICATIONCENTER_UNIT_FIXTURE \
    -I "$STAGE" \
    -module-name UIKit \
    -emit-module-path "$STAGE/UIKit.swiftmodule" \
    -o "$STAGE/libUIKit.dylib" \
    "$STAGE/libFoundation.dylib" \
    "$STAGE_SOURCES/StagedUIKit.swift"
test -s "$STAGE/libUIKit.dylib" || die 'unit-fixture libUIKit.dylib missing'

mapfile -t SOURCES < "$FRAMEWORK_ROOT/notificationcenter_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$REPO_ROOT/$relative")
done

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -D NOTIFICATIONCENTER_UNIT_FIXTURE \
    -D NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT \
    -I "$STAGE" \
    -module-name NotificationCenter \
    -emit-module-path "$STAGE/NotificationCenter.swiftmodule" \
    -o "$STAGE/libNotificationCenter.dylib" \
    "$STAGE/libFoundation.dylib" "$STAGE/libUIKit.dylib" \
    "${SOURCE_PATHS[@]}"
test -s "$STAGE/libNotificationCenter.dylib" \
    || die 'unit-fixture libNotificationCenter.dylib was not produced'

printf 'NOTIFICATIONCENTER_UNIT_FIXTURE_STANDALONE_ONLY\n'
printf 'NOTIFICATIONCENTER_UNIT_FIXTURE_NOT_PLATFORM_IDENTITY_EVIDENCE\n'
