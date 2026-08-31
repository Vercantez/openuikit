#!/bin/bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
OUT=$(mktemp -d /tmp/security-framework-host.XXXXXX)
cleanup() {
    case "$OUT" in
        /tmp/security-framework-host.*|/private/tmp/security-framework-host.*)
            rm -rf -- "$OUT" ;;
        *) printf 'refusing unsafe cleanup path: %s\n' "$OUT" >&2 ;;
    esac
}
trap cleanup EXIT

xcrun swiftc -parse-as-library -swift-version 5 \
    -module-name Security -emit-module \
    -emit-module-path "$OUT/Security.swiftmodule" \
    -emit-library -o "$OUT/libSecurity.dylib" \
    "$ROOT/full/security/Security.swift"

xcrun swiftc -swift-version 5 \
    -I "$OUT" -L "$OUT" -lSecurity \
    "$HERE/SecurityHostRuntime.swift" -o "$OUT/SecurityHostRuntime"

if xcrun otool -L "$OUT/libSecurity.dylib" \
    | grep -F '/System/Library/Frameworks/Security.framework/' >/dev/null; then
    printf 'portable Security dylib loads Apple Security.framework\n' >&2
    exit 3
fi

DYLD_LIBRARY_PATH="$OUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUT/SecurityHostRuntime" | tee "$OUT/runtime.log"
grep -Fx \
    'SECURITY_HOST_OK keychain=crud random=system code-signing=unavailable' \
    "$OUT/runtime.log" >/dev/null
