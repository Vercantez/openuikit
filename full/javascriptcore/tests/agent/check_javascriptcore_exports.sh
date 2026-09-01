#!/usr/bin/env bash
# Verify libJavaScriptCore.dylib exports unmangled public C JS* functions.
# Intended for a future clean EC2 run after the dylib is installed; the isolated
# host gate does not invoke this script.
set -euo pipefail

die() {
    printf 'JAVASCRIPTCORE_EXPORT_GATE_FAIL: %s\n' "$*" >&2
    exit 1
}

[ "${1-}" != "" ] || die 'usage: check_javascriptcore_exports.sh path/to/libJavaScriptCore.dylib'
dylib=$1
[ -f "$dylib" ] || die "missing dylib: $dylib"

list=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/javascriptcore_c_exports.txt
[ -f "$list" ] || die "missing export list: $list"

symbols=$(mktemp)
cleanup() { rm -f -- "$symbols"; }
trap cleanup EXIT HUP INT TERM

if command -v nm >/dev/null 2>&1; then
    nm -D --defined-only "$dylib" 2>/dev/null | awk '{ print $NF }' | sed 's/^_//' >"$symbols" \
        || nm --defined-only "$dylib" | awk '{ print $NF }' | sed 's/^_//' >"$symbols"
elif command -v llvm-nm >/dev/null 2>&1; then
    llvm-nm -D --defined-only "$dylib" | awk '{ print $NF }' | sed 's/^_//' >"$symbols"
elif command -v readelf >/dev/null 2>&1; then
    readelf -Ws "$dylib" | awk '{ print $NF }' | sed 's/@.*//; s/^_//' >"$symbols"
else
    die 'nm, llvm-nm, or readelf is required'
fi

missing=0
while IFS= read -r name; do
    [ -n "$name" ] || continue
    if ! grep -Fqx -- "$name" "$symbols"; then
        printf 'missing unmangled export: %s\n' "$name" >&2
        missing=$((missing + 1))
    fi
done <"$list"

[ "$missing" -eq 0 ] || die "$missing public JS* symbols are mangled or absent"
printf 'JAVASCRIPTCORE_EXPORT_GATE_OK count=%s dylib=%s\n' "$(grep -c . "$list")" "$dylib"
