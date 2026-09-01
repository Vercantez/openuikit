#!/usr/bin/env bash
# Compile, link, and run the independent C ABI probe against an installed
# JavaScriptCore (headers + libJavaScriptCore.dylib). This is prepared for a
# future clean EC2 run that first builds guest Foundation, the guest Swift
# runtime, and this framework's dylib. It is not the isolated host gate and
# must not be used to claim integrated Linux success.
#
# Required environment:
#   JSC_INCLUDE  directory containing JavaScriptCore.h / JSBase.h / module.modulemap
#   JSC_LIB      directory containing libJavaScriptCore.dylib
# Optional:
#   LD_LIBRARY_PATH must include JSC_LIB and the guest Swift runtime (for example
#   /usr/lib/swift/linux) so the C client loads libJavaScriptCore.dylib.
set -euo pipefail

die() {
    printf 'JAVASCRIPTCORE_CABI_PROBE_FAIL: %s\n' "$*" >&2
    exit 1
}

: "${JSC_INCLUDE:?set JSC_INCLUDE to the installed JavaScriptCore headers}"
: "${JSC_LIB:?set JSC_LIB to the directory that contains libJavaScriptCore.dylib}"
[ -f "$JSC_INCLUDE/JavaScriptCore.h" ] || die "JavaScriptCore.h missing under $JSC_INCLUDE"
[ -f "$JSC_LIB/libJavaScriptCore.dylib" ] || die "libJavaScriptCore.dylib missing under $JSC_LIB"

AGENT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/javascriptcore-cabi.XXXXXX")
cleanup() { rm -rf -- "$TMP"; }
trap cleanup EXIT HUP INT TERM

cc_cmd=${CC:-clang}
"$cc_cmd" -std=c11 -Wall -Werror -I "$JSC_INCLUDE" \
    "$AGENT/JavaScriptCoreCABI.c" \
    -L "$JSC_LIB" -lJavaScriptCore \
    -o "$TMP/javascriptcore-cabi"

export LD_LIBRARY_PATH="$JSC_LIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
output=$("$TMP/javascriptcore-cabi")
printf '%s\n' "$output" | grep -Fqx -- 'JAVASCRIPTCORE_CABI_PROBE_OK' \
    || die 'C ABI probe did not emit JAVASCRIPTCORE_CABI_PROBE_OK'
printf '%s\n' "$output"

bash "$AGENT/check_javascriptcore_exports.sh" "$JSC_LIB/libJavaScriptCore.dylib"
if command -v ldd >/dev/null 2>&1; then
    ldd "$TMP/javascriptcore-cabi" | grep -F -- 'libJavaScriptCore.dylib' \
        || die 'C client did not link libJavaScriptCore.dylib'
fi
