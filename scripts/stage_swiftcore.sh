#!/bin/bash
# stage_swiftcore.sh -- put a cross-built Swift standard library where machorun
# and its Swift gate can find it.
#
#   scripts/stage_swiftcore.sh                 stage from the default location
#   scripts/stage_swiftcore.sh <artifacts-dir> stage from somewhere else
#   scripts/stage_swiftcore.sh --check         say what is staged, change nothing
#
# THIS IS AN EXTERNAL INPUT AND THE SCRIPT SAYS SO LOUDLY. machorun does not
# build libswiftCore.dylib. It is cross-built from swift.org source on a Linux
# host by a separate project (~/swiftcore-macho -- see its docs/BUILD_LOG.md),
# and it is 9.9 MB, so it is not committed here. Everything this script writes
# lands under darwin/usr/ or build/, both of which are .gitignored precisely
# because they hold things that were built rather than written.
#
# What gets staged, and why each piece is needed:
#
#   darwin/usr/lib/swift/libswiftCore.dylib
#       The runtime itself. Its install name is /usr/lib/swift/libswiftCore.dylib,
#       so this is the one path machorun's darwin-root prefix map will look at.
#
#   darwin/usr/lib/libswiftcompat.dylib
#       29 symbols libswiftCore imports that machorun's self-hosted Darwin
#       userland does not carry -- compiler-rt's 128-bit division, a handful of
#       libc and dyld gaps, four libc++abi type_info vtables. A GUEST MUST LINK
#       THIS EXPLICITLY, which is why a Swift binary built by Apple's own
#       toolchain does not run here yet; see docs/UNIMPLEMENTED.md#swift-compat.
#
#   build/swift-res/
#       A Swift resource directory assembled from the same build's
#       Swift.swiftmodule, so `swiftc -target arm64-apple-macos` can compile
#       against exactly the library it will run against. The `shims` half is
#       NOT staged here: it must come from the compiler doing the compiling, so
#       scripts/swift_gate.sh copies it inside the container.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC_DEFAULT="$HOME/swiftcore-macho/artifacts"
MODE=stage
SRC=""
for a in "$@"; do
    case "$a" in
        --check) MODE=check ;;
        -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
        -*) echo "stage_swiftcore.sh: unknown option $a" >&2; exit 64 ;;
        *) SRC="$a" ;;
    esac
done
SRC="${SRC:-${SWIFTCORE_ARTIFACTS:-$SRC_DEFAULT}}"

CORE="$ROOT/darwin/usr/lib/swift/libswiftCore.dylib"
COMPAT="$ROOT/darwin/usr/lib/libswiftcompat.dylib"
RES="$ROOT/build/swift-res"

if [ "$MODE" = check ]; then
    ok=0
    for f in "$CORE" "$COMPAT" "$RES/macosx/Swift.swiftmodule/arm64-apple-macos.swiftmodule"; do
        if [ -f "$f" ]; then printf '  present  %s\n' "${f#$ROOT/}"
        else printf '  MISSING  %s\n' "${f#$ROOT/}"; ok=1; fi
    done
    exit $ok
fi

# ------------------------------------------------------------- preconditions
# Naming every missing piece beats failing on the first one: whoever runs this
# on a fresh box wants the whole list, not three rounds of one-at-a-time.
missing=()
[ -f "$SRC/swift-macosx/arm64/libswiftCore.dylib" ] || missing+=("swift-macosx/arm64/libswiftCore.dylib")
[ -f "$SRC/libswiftcompat.dylib" ]                  || missing+=("libswiftcompat.dylib")
[ -d "$SRC/swift-macosx/Swift.swiftmodule" ]        || missing+=("swift-macosx/Swift.swiftmodule/")
if [ ${#missing[@]} -gt 0 ]; then
    echo "stage_swiftcore.sh: nothing to stage from $SRC" >&2
    for m in "${missing[@]}"; do echo "    missing: $m" >&2; done
    echo "  That tree is built by ~/swiftcore-macho (docs/BUILD_LOG.md §7)." >&2
    echo "  Point this script at it:  scripts/stage_swiftcore.sh /path/to/artifacts" >&2
    exit 66
fi

# libswiftCore is useless to us as anything but an arm64 Mach-O dylib, and a
# wrong-format file here would surface much later as a confusing load error.
case "$(file -b "$SRC/swift-macosx/arm64/libswiftCore.dylib")" in
    *"Mach-O 64-bit"*arm64*) ;;
    *) echo "stage_swiftcore.sh: $SRC/swift-macosx/arm64/libswiftCore.dylib is not an arm64 Mach-O:" >&2
       echo "    $(file -b "$SRC/swift-macosx/arm64/libswiftCore.dylib")" >&2
       exit 65 ;;
esac

mkdir -p "$ROOT/darwin/usr/lib/swift" "$RES/macosx/arm64"
cp -f "$SRC/swift-macosx/arm64/libswiftCore.dylib" "$CORE"
cp -f "$SRC/libswiftcompat.dylib"                  "$COMPAT"
cp -Rf "$SRC/swift-macosx/Swift.swiftmodule"       "$RES/macosx/"
cp -f "$SRC/swift-macosx/arm64/libswiftCore.dylib" "$RES/macosx/arm64/"

printf '   %-42s %8d bytes\n' "darwin/usr/lib/swift/libswiftCore.dylib" "$(wc -c < "$CORE")"
printf '   %-42s %8d bytes\n' "darwin/usr/lib/libswiftcompat.dylib"     "$(wc -c < "$COMPAT")"
printf '   %-42s\n'           "build/swift-res/macosx/Swift.swiftmodule"
echo "   staged from $SRC"
