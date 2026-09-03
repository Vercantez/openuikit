#!/usr/bin/env bash
# gen_swift_tbd.sh -- TAPI v4 .tbd from one x86_64 Mach-O Swift dylib.
#
# machorun/scripts/gen_tbd.sh only covers darwin/usr/lib (libSystem/objc/c++).
# The widget gate's inventories name $SYS/usr/lib/swift/*.tbd; a dylib stand-in
# does not satisfy lstat. Never copy an arm64-macos .tbd.
#
#   scripts/x86/gen_swift_tbd.sh <dylib> <dest.tbd>
#   scripts/x86/gen_swift_tbd.sh --check <dylib> <dest.tbd>
#
# Round-trip (--check / test_gen_swift_tbd.sh): every defined-external symbol
# the dylib exports appears in the .tbd, and every LC_REEXPORT_DYLIB is
# recorded. Empty .tbd is a linker lie.
set -euo pipefail
export LC_ALL=C

MODE=generate
if [ "${1:-}" = --check ]; then
    MODE=check
    shift
fi
if [ "${1:-}" = -h ] || [ "${1:-}" = --help ] || [ $# -ne 2 ]; then
    sed -n '2,16p' "$0"
    exit 64
fi
DYLIB=$1
DEST=$2

die() { echo "gen_swift_tbd: $*" >&2; exit 1; }

[ -f "$DYLIB" ] || die "no dylib $DYLIB"
llvm-otool-18 -hv "$DYLIB" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' \
    || die "not X86_64 Mach-O: $DYLIB"

NM=
for c in llvm-nm-18 llvm-nm nm; do
    command -v "$c" >/dev/null 2>&1 && { NM=$c; break; }
done
[ -n "$NM" ] || die "no nm (llvm-nm-18, llvm-nm or nm)"
OTOOL=
for c in llvm-otool-18 llvm-otool otool; do
    command -v "$c" >/dev/null 2>&1 && { OTOOL=$c; break; }
done
[ -n "$OTOOL" ] || die "no otool (llvm-otool-18, llvm-otool or otool)"

TBD_TARGET=x86_64-macos
INSTALL=$("$OTOOL" -D "$DYLIB" 2>/dev/null | awk 'NR==2 { print; exit }')
[ -n "$INSTALL" ] || INSTALL=/usr/lib/swift/$(basename "$DYLIB")

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Defined-external names. Drop fat-slice banners the way gen_tbd.sh does.
"$NM" --defined-only --extern-only --format=just-symbols "$DYLIB" 2>/dev/null \
    | sed 's/[[:space:]]*$//' \
    | grep -vE '^$|\(for architecture .*\):$|^[^ ]*:$' \
    | sort -u > "$TMP/syms"
[ -s "$TMP/syms" ] || die "empty export list from $DYLIB (empty .tbd is a linker lie)"

# Weak defs from the long nm form (type W/V).
"$NM" --defined-only --extern-only "$DYLIB" 2>/dev/null \
    | awk '$2 ~ /^[WV]$/ { print $NF }' \
    | sed 's/[[:space:]]*$//' | sort -u > "$TMP/weak"

# ObjC classes: _OBJC_CLASS_$_Foo -> Foo
awk '
    /^\s*_OBJC_CLASS_\$_/ {
        s=$0
        sub(/^[[:space:]]*/, "", s)
        sub(/^_OBJC_CLASS_\$_/, "", s)
        if (s != "") print s
    }
' "$TMP/syms" | sort -u > "$TMP/objc"

# LC_REEXPORT_DYLIB install names (not every otool -L load).
"$OTOOL" -l "$DYLIB" 2>/dev/null \
    | awk '/LC_REEXPORT_DYLIB/{f=1} f&&/^ *name /{print $2; f=0}' \
    | sort -u > "$TMP/reexport"

yaml_list() {
    local f=$1
    [ -s "$f" ] || return 0
    sed "s/^/                  '/; s/\$/',/" "$f"
}

emit() {
    local dest=$1
    {
        echo "--- !tapi-tbd"
        echo "tbd-version:     4"
        echo "targets:         [ $TBD_TARGET ]"
        echo "install-name:    '$INSTALL'"
        echo "current-version: 1"
        echo "compatibility-version: 1"
        echo "exports:"
        echo "  - targets:   [ $TBD_TARGET ]"
        echo "    symbols:   ["
        yaml_list "$TMP/syms"
        echo "               ]"
        if [ -s "$TMP/objc" ]; then
            echo "    objc-classes: ["
            yaml_list "$TMP/objc"
            echo "               ]"
        fi
        if [ -s "$TMP/weak" ]; then
            echo "    weak-def-symbols: ["
            yaml_list "$TMP/weak"
            echo "               ]"
        fi
        if [ -s "$TMP/reexport" ]; then
            echo "reexported-libraries:"
            echo "  - targets:   [ $TBD_TARGET ]"
            echo "    libraries: ["
            yaml_list "$TMP/reexport"
            echo "               ]"
        fi
        echo "..."
    } > "$dest"
}

emit "$TMP/out.tbd"
[ -s "$TMP/out.tbd" ] || die "emit produced an empty file"

roundtrip() {
    local tbd=$1 miss=0
    [ -s "$tbd" ] || die "--check: $tbd missing or empty"
    grep -q 'x86_64-macos' "$tbd" || die "--check: $tbd does not name x86_64-macos"
    grep -q '^\.\.\.$' "$tbd" || die "--check: $tbd missing document-end ..."
    grep -o "'[^']*'" "$tbd" | tr -d "'" | LC_ALL=C sort -u > "$TMP/have"
    if ! comm -13 "$TMP/have" "$TMP/syms" > "$TMP/sym.miss"; then
        :
    fi
    if [ -s "$TMP/sym.miss" ]; then
        echo "gen_swift_tbd: missing from $tbd:" >&2
        head -20 "$TMP/sym.miss" >&2
        miss=1
    fi
    while IFS= read -r s; do
        [ -n "$s" ] || continue
        grep -F -q "$s" "$tbd" || {
            echo "gen_swift_tbd: reexport not recorded in $tbd: $s" >&2
            miss=1
        }
    done < "$TMP/reexport"
    [ "$miss" -eq 0 ] || die "round-trip failed for $DYLIB -> $tbd"
}

if [ "$MODE" = check ]; then
    roundtrip "$DEST"
    echo "gen_swift_tbd: CHECK ok $DEST ($(wc -l < "$TMP/syms") symbols)"
    exit 0
fi

mkdir -p "$(dirname "$DEST")"
cp -f "$TMP/out.tbd" "$DEST"
roundtrip "$DEST"
printf 'gen_swift_tbd: %s  %d symbols  %d bytes\n' \
    "$DEST" "$(wc -l < "$TMP/syms")" "$(wc -c < "$DEST")"
