#!/bin/bash
# build_json_host.sh -- MACOS ONLY.  Link the JSON oracle runner against the
# SAME FoundationEssentials objects `build_fe_host.sh` produced, and run it.
#
# WHAT THIS ISOLATES.  Apple's toolchain, Apple's SDK, native: no machorun, no
# staged sysroot, no Mach-O loader.  A failure here belongs to the PORT.  A
# failure that appears only under machorun belongs to the STACK.
#
# It does NOT rebuild FoundationEssentials -- `build_fe_host.sh` does that, and
# rebuilding it here would make this script's result depend on a 202-file
# compile it does not own.  It REFUSES to run if the objects are missing, and
# it prints their sizes and mtimes, because a stale object file passes every
# check that does not look at it.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SF=${SF:-$ROOT/scratch/swift-foundation}
OUT=${OUT:-$ROOT/scratch/fe_host}
J=${J:-$ROOT/full/oracle-json}
TARGET=${TARGET:-arm64-apple-macos15.0}

need=(FoundationEssentials.o FoundationEssentials.swiftmodule
      InternalCollectionsUtilities.o OrderedCollections.o _RopeModule.o
      platform_shims.o string_shims.o uuid.o)
# BSD stat and GNU stat take different flags, and this machine has GNU
# coreutils shadowing the BSD tools while the script is macOS-only.  Try both
# rather than print an empty column, which is how a size check silently stops
# checking anything.
fsize() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1"; }
fmtime() { stat -f%Sm -t%FT%T "$1" 2>/dev/null || stat -c%y "$1" | cut -c1-19; }

missing=0
echo "== inputs from $OUT (built by build_fe_host.sh, NOT by this script)"
for f in "${need[@]}"; do
    if [ -f "$OUT/$f" ]; then
        printf "   ok      %-34s %10s bytes  %s\n" "$f" \
            "$(fsize "$OUT/$f")" "$(fmtime "$OUT/$f")"
    else
        printf "   MISSING %s\n" "$f"; missing=$((missing + 1))
    fi
done
[ "$missing" -eq 0 ] || { echo "== run build_fe_host.sh first" >&2; exit 3; }

echo "== json_runner (host route)"
xcrun swiftc -target "$TARGET" -wmo -O \
    -module-name json_runner -I "$OUT" \
    -Xcc -fmodule-map-file="$SF/Sources/_FoundationCShims/include/module.modulemap" \
    -Xcc -I"$SF/Sources/_FoundationCShims/include" \
    -o "$OUT/json_runner" \
    "$J/json_canon.swift" "$J/json_probes.swift" "$J/json_runner.swift" \
    "$OUT/FoundationEssentials.o" "$OUT/InternalCollectionsUtilities.o" \
    "$OUT/OrderedCollections.o" "$OUT/_RopeModule.o" \
    "$OUT/platform_shims.o" "$OUT/string_shims.o" "$OUT/uuid.o"

echo "== built $OUT/json_runner"
shasum -a 256 "$OUT/json_runner"
