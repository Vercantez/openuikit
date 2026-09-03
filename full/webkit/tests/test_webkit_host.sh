#!/usr/bin/env bash
# Sealed warnings-as-errors host gate for portable WebKit.
# A missing toolchain or product refuses loudly. OpenUIKit SwiftPM is not
# required: Linux compiles the guest sources against a test-only UIKit shim.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WEBKIT=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$WEBKIT/../.." && pwd)

die() {
    printf 'WEBKIT_HOST_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

if command -v swiftc >/dev/null 2>&1; then
    SWIFTC=$(command -v swiftc)
elif [ -x /opt/swift/usr/bin/swiftc ]; then
    SWIFTC=/opt/swift/usr/bin/swiftc
else
    die 'swiftc is not on PATH'
fi

for stale in .build build scratch; do
    [ ! -e "$WEBKIT/$stale" ] || die "stale product directory exists: $stale"
done

[ -f "$WEBKIT/webkit_guest_sources.txt" ] || die 'guest sources manifest is missing'
[ -f "$HERE/WebKitHostRuntime.swift" ] || die 'host runtime is missing'
[ -f "$HERE/WebKitOrdinaryImportNegative.swift" ] || die 'ordinary-import negative test is missing'
[ -f "$HERE/HackersWebKitSurface.swift" ] || die 'Hackers surface gate is missing'
[ -f "$HERE/WebKitHostUIKitShim.swift" ] || die 'host UIKit shim is missing'
if grep -Fq 'WebKitHostUIKitShim.swift' "$WEBKIT/webkit_guest_sources.txt"; then
    die 'test-only UIKit shim leaked into the guest source manifest'
fi

OUT=$(mktemp -d "${TMPDIR:-/tmp}/webkit-host-gate.XXXXXX") || die 'cannot create isolated stage'
cleanup() {
    case "$OUT" in
        /tmp/webkit-host-gate.*|/private/tmp/webkit-host-gate.*)
            rm -rf -- "$OUT"
            ;;
        *)
            if [ -n "${TMPDIR:-}" ]; then
                case "$OUT" in
                    "$TMPDIR"/webkit-host-gate.*) rm -rf -- "$OUT" ;;
                    *) printf 'WEBKIT_HOST_GATE_REFUSING: refusing unsafe cleanup path: %s\n' "$OUT" >&2 ;;
                esac
            else
                printf 'WEBKIT_HOST_GATE_REFUSING: refusing unsafe cleanup path: %s\n' "$OUT" >&2
            fi
            ;;
    esac
}
trap cleanup EXIT

SOURCE_PATHS=()
source_count=0
while IFS= read -r relative; do
    [ -n "$relative" ] || continue
    [ -f "$ROOT/$relative" ] || die "missing WebKit source: $relative"
    SOURCE_PATHS+=("$ROOT/$relative")
    source_count=$((source_count + 1))
done < "$WEBKIT/webkit_guest_sources.txt"
[ "$source_count" -ge 6 ] || die "WebKit source count $source_count, expected at least 6"
grep -qx 'full/webkit/WebKit.swift' "$WEBKIT/webkit_guest_sources.txt" \
    || die 'guest source manifest lacks primary WebKit.swift'

uname_s=$(uname -s)
if [ "$uname_s" = Darwin ]; then
    UIKIT_LIB=$OUT/libUIKit.dylib
    WEBKIT_LIB=$OUT/libWebKit.dylib
else
    UIKIT_LIB=$OUT/libUIKit.so
    WEBKIT_LIB=$OUT/libWebKit.so
fi

"$SWIFTC" -warnings-as-errors -parse-as-library \
    -emit-module -emit-library \
    -module-name UIKit \
    -emit-module-path "$OUT/UIKit.swiftmodule" \
    "$HERE/WebKitHostUIKitShim.swift" \
    -o "$UIKIT_LIB" \
    || die 'UIKit shim failed warnings-as-errors compilation'

INSTALL_NAME_FLAGS=()
if [ "$uname_s" = Darwin ]; then
    INSTALL_NAME_FLAGS=(-Xlinker -install_name -Xlinker @rpath/libWebKit.dylib)
fi

"$SWIFTC" -warnings-as-errors -parse-as-library \
    -emit-module -emit-library \
    -module-name WebKit \
    -emit-module-path "$OUT/WebKit.swiftmodule" \
    -I "$OUT" -L "$OUT" -lUIKit \
    -D PORTABLE_WEBKIT_HOST \
    "${INSTALL_NAME_FLAGS[@]}" \
    "${SOURCE_PATHS[@]}" \
    -o "$WEBKIT_LIB" \
    || die 'WebKit sources failed warnings-as-errors compilation'
test -s "$WEBKIT_LIB" || die 'libWebKit was not produced'

"$SWIFTC" -warnings-as-errors -parse-as-library -typecheck \
    -I "$OUT" \
    "$HERE/HackersWebKitSurface.swift" \
    || die 'Hackers WebKit surface failed warnings-as-errors typecheck'

"$SWIFTC" -warnings-as-errors -parse-as-library \
    -I "$OUT" -L "$OUT" -lWebKit -lUIKit \
    -Xlinker -rpath -Xlinker "$OUT" \
    "$HERE/WebKitHostRuntime.swift" \
    -o "$OUT/WebKitHostRuntime" \
    || die 'host runtime failed warnings-as-errors compilation'

run_with_library() {
    if [ "$uname_s" = Darwin ]; then
        DYLD_LIBRARY_PATH="$OUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" "$@"
    else
        LD_LIBRARY_PATH="$OUT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$@"
    fi
}
run_with_library "$OUT/WebKitHostRuntime" | tee "$OUT/runtime.log"
grep -Fx \
    'WEBKIT_HOST_RUNTIME_OK configuration=copied state=retained media=paired insets=retained background=retained policies=honored navigation=engine-unavailable kvo=string-keypath history=in-memory error=WKError rendering=absent' \
    "$OUT/runtime.log" >/dev/null \
    || die 'host runtime marker is missing'

if "$SWIFTC" -parse-as-library -typecheck -I "$OUT" \
    "$HERE/WebKitOrdinaryImportNegative.swift" \
    > "$OUT/negative.log" 2>&1; then
    cat "$OUT/negative.log" >&2
    die 'ordinary-import client compiled; host-only control seams leaked'
fi
grep -Eq 'WebKitHostControl|_portableLastError|_portableCopyForWebView|_portableState' \
    "$OUT/negative.log" \
    || {
        cat "$OUT/negative.log" >&2
        die 'ordinary-import refusal did not name a host-only control seam'
    }

if command -v llvm-nm-18 >/dev/null 2>&1; then
    NM=(llvm-nm-18 -g)
elif [ "$uname_s" = Darwin ] && command -v xcrun >/dev/null 2>&1; then
    NM=(xcrun nm -gU)
elif command -v nm >/dev/null 2>&1; then
    NM=(nm -g)
else
    die 'nm is unavailable'
fi
nm_out=$("${NM[@]}" "$WEBKIT_LIB" 2>/dev/null || true)
printf '%s\n' "$nm_out" | grep -F 'WKWebView' >/dev/null \
    || die 'libWebKit does not export WKWebView'
printf '%s\n' "$nm_out" | grep -F 'WKError' >/dev/null \
    || die 'libWebKit does not export WKError'
printf '%s\n' "$nm_out" | grep -F 'WKBackForwardList' >/dev/null \
    || die 'libWebKit does not export WKBackForwardList'
if printf '%s\n' "$nm_out" | grep -F 'WKPortableError' >/dev/null; then
    die 'libWebKit still exports the retired WKPortableError name'
fi
exported=$(printf '%s\n' "$nm_out" | grep -c 'WK' || true)

if [ "$uname_s" = Darwin ]; then
    command -v xcrun >/dev/null 2>&1 || die 'xcrun is unavailable on Darwin'
    [ "$(xcrun otool -D "$WEBKIT_LIB" | grep -Fc '@rpath/libWebKit.dylib')" -eq 1 ] \
        || die 'install ID is not @rpath/libWebKit.dylib'
    if xcrun otool -L "$WEBKIT_LIB" | grep -F '/WebKit.framework/' >/dev/null; then
        die 'portable libWebKit loads Apple WebKit.framework'
    fi
fi

printf 'WEBKIT_HOST_DYLIB_OK platform=%s apple-webkit-load=absent exported-WK-symbols=%s sources=%s\n' \
    "$uname_s" "$exported" "$source_count"
printf 'WEBKIT_HOST_GATE_OK module=WebKit warnings-as-errors=1 ordinary-import=hidden runtime=fail-closed\n'
