#!/bin/bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WEBKIT=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$WEBKIT/../.." && pwd)
OPENUIKIT_SOURCE=${1:-${OPENUIKIT_SOURCE:-}}
[ -n "$OPENUIKIT_SOURCE" ] || {
    printf 'usage: %s /path/to/pinned/OpenUIKit\n' "$0" >&2
    exit 2
}
[ -f "$OPENUIKIT_SOURCE/Package.swift" ] || {
    printf 'not an OpenUIKit package: %s\n' "$OPENUIKIT_SOURCE" >&2
    exit 2
}

OUT=$(mktemp -d /tmp/webkit-host-gate.XXXXXX)
cleanup() {
    case "$OUT" in
        /tmp/webkit-host-gate.*|/private/tmp/webkit-host-gate.*)
            rm -rf -- "$OUT"
            ;;
        *)
            printf 'refusing unsafe cleanup path: %s\n' "$OUT" >&2
            ;;
    esac
}
trap cleanup EXIT

mkdir -p "$OUT/Sources/WebKit"
cp "$HERE/HostPackage.swift" "$OUT/Package.swift"
while IFS= read -r relative; do
    [ -n "$relative" ] || continue
    cp "$ROOT/$relative" "$OUT/Sources/WebKit/$(basename "$relative")"
done < "$WEBKIT/webkit_guest_sources.txt"

OPENUIKIT_SOURCE="$OPENUIKIT_SOURCE" \
    swift build --package-path "$OUT" -c release --product WebKit \
    > "$OUT/swift-build.log" 2>&1
BIN=$(OPENUIKIT_SOURCE="$OPENUIKIT_SOURCE" \
    swift build --package-path "$OUT" -c release --show-bin-path)
[ -f "$BIN/libWebKit.dylib" ] || {
    printf 'missing dynamic WebKit product: %s\n' "$BIN/libWebKit.dylib" >&2
    exit 3
}

xcrun swiftc -parse-as-library "$HERE/WebKitHostRuntime.swift" \
    -I "$BIN/Modules" -L "$BIN" -lWebKit \
    -Xcc -fmodule-map-file="$BIN/CPortableIO.build/module.modulemap" \
    -Xcc -I -Xcc "$OPENUIKIT_SOURCE/Sources/CPortableIO/include" \
    -Xcc -fmodule-map-file="$BIN/CSTBTrueType.build/module.modulemap" \
    -Xcc -I -Xcc "$OPENUIKIT_SOURCE/Sources/CSTBTrueType/include" \
    -Xcc -fmodule-map-file="$OPENUIKIT_SOURCE/Sources/CQuartz/include/module.modulemap" \
    -Xcc -I -Xcc "$OPENUIKIT_SOURCE/Sources/CQuartz/include" \
    -o "$OUT/WebKitHostRuntime"
DYLD_LIBRARY_PATH="$BIN${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUT/WebKitHostRuntime" | tee "$OUT/runtime.log"
grep -Fx \
    'WEBKIT_HOST_RUNTIME_OK configuration=copied state=retained policies=honored navigation=engine-unavailable rendering=absent' \
    "$OUT/runtime.log" >/dev/null

[ "$(xcrun otool -D "$BIN/libWebKit.dylib" | grep -Fc '@rpath/libWebKit.dylib')" -eq 1 ]
! xcrun otool -L "$BIN/libWebKit.dylib" | grep -F '/WebKit.framework/' >/dev/null
xcrun nm -gU "$BIN/libWebKit.dylib" | grep -F 'WKWebView' >/dev/null
printf 'WEBKIT_HOST_DYLIB_OK install-id=@rpath/libWebKit.dylib apple-webkit-load=absent\n'
