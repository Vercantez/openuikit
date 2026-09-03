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

if command -v xcrun >/dev/null 2>&1; then
    SWIFTC=(xcrun swiftc)
else
    SWIFTC=(swiftc)
fi

mapfile -t SOURCES < "$ROOT/full/security/security_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$ROOT/$relative")
done

"${SWIFTC[@]}" -parse-as-library -swift-version 5 \
    -module-name Security -emit-module \
    -emit-module-path "$OUT/Security.swiftmodule" \
    -emit-library -o "$OUT/libSecurity.dylib" \
    "${SOURCE_PATHS[@]}"

"${SWIFTC[@]}" -swift-version 5 \
    -I "$OUT" \
    "$HERE/SecurityHostRuntime.swift" \
    "$OUT/libSecurity.dylib" \
    -o "$OUT/SecurityHostRuntime"

if command -v otool >/dev/null 2>&1 || command -v xcrun >/dev/null 2>&1; then
    if xcrun otool -L "$OUT/libSecurity.dylib" 2>/dev/null \
        | grep -F '/System/Library/Frameworks/Security.framework/' >/dev/null; then
        printf 'portable Security dylib loads Apple Security.framework\n' >&2
        exit 3
    fi
fi

export LD_LIBRARY_PATH="$OUT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export DYLD_LIBRARY_PATH="$OUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
"$OUT/SecurityHostRuntime" | tee "$OUT/runtime.log"
grep -Fx \
    'SECURITY_HOST_OK keychain=crud random=system code-signing=unavailable' \
    "$OUT/runtime.log" >/dev/null
