#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/private/tmp}/foundation-extension-host.XXXXXX")

cleanup() {
    find "$WORK" -depth -delete
}
trap cleanup EXIT

SWIFTC=(xcrun swiftc -swift-version 6 -warnings-as-errors)
SOURCE="$ROOT/full/foundation/NSExtensionHost.swift"
ORACLE="$ROOT/full/foundation/tests/FoundationExtensionHostOracle.swift"
RUNTIME="$ROOT/full/foundation/tests/FoundationExtensionHostRuntime.swift"
GOLDEN="$ROOT/full/foundation/tests/foundation-extension-host-apple-xcode-26.1.txt"

"${SWIFTC[@]}" -D FOUNDATION_EXTENSION_HOST -parse-as-library \
    -module-name FoundationExtensionHostSupport \
    -emit-module \
    -emit-module-path "$WORK/FoundationExtensionHostSupport.swiftmodule" \
    -emit-object -o "$WORK/FoundationExtensionHostSupport.o" "$SOURCE"
"${SWIFTC[@]}" "$ORACLE" -o "$WORK/oracle"
"${SWIFTC[@]}" -I "$WORK" "$RUNTIME" \
    "$WORK/FoundationExtensionHostSupport.o" -o "$WORK/runtime"

"$WORK/oracle" > "$WORK/oracle.txt"
"$WORK/runtime" > "$WORK/runtime.txt"
cmp "$GOLDEN" "$WORK/oracle.txt"
head -n 7 "$WORK/runtime.txt" > "$WORK/runtime-oracle-prefix.txt"
cmp "$GOLDEN" "$WORK/runtime-oracle-prefix.txt"
grep -Fx \
    'FOUNDATION_EXTENSION_RUNTIME coding=secure,copy,metadata context=fail-closed callbacks=66 concurrency=64' \
    "$WORK/runtime.txt" >/dev/null
grep -Fx 'FOUNDATION_EXTENSION_HOST_RUNTIME_OK' \
    "$WORK/runtime.txt" >/dev/null

printf '%s\n' \
    'FOUNDATION_EXTENSION_HOST_TEST_OK oracle=xcode-26.1 signatures=exact coding=secure context=fail-closed concurrency=64'
