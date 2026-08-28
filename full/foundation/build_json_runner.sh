#!/bin/bash
# build_json_runner.sh -- link the JSON oracle runner as an arm64-apple-macos
# Mach-O executable, to run under machorun.  Runs INSIDE the Linux container.
#
# This is `build_url_runner.sh` with a different runner source, and the two
# differ in one way worth stating: that script's header still describes the
# state in which it LINKED and did not LOAD (task #72, four "missing" Swift
# runtime dylibs).  #72 is closed -- the dylibs were on disk in the iOS 26.1
# simruntime and `stage_swift_overlays.sh` stages the transitive closure of
# NINE into `scratch/mrroot_fe`.  So the default ROOTDIR here is mrroot_fe,
# the root that works, not mrroot_full.
#
# swiftcore-FIRST on the link line, for the reason build_full.sh gives: the
# staged libSystem.tbd still advertises swift_*, so a system-first link binds
# _swift_release into libSystem, which no longer defines it, and the guest dies
# at load.
#
# CHECK THE ARTIFACT, NOT THE EXIT STATUS.  A successful `ld` means little
# here, because the load commands it writes name libraries that may not be in
# the guest root at all.  The tail of this file checks every LC_LOAD_DYLIB
# against the root the binary will actually run in and prints the non-lazy bind
# count beside each, so "absent and unused" and "absent and needed" can never
# be the same line.
set -euo pipefail
W=${W:-/w}
SYS=${SYS:-$W/scratch/sysroot_fe4}
ROOTDIR=${ROOTDIR:-$W/scratch/mrroot_fe}
OUT=${OUT:-$W/scratch/fe4_out}
J=${J:-$W/full/oracle-json}
TARGET=${TARGET:-arm64-apple-macos15.0}
mkdir -p "$OUT"

# The 202-file FoundationEssentials compile belongs to build_fe.sh.  Refuse
# rather than silently link against whatever is lying in $OUT: a stale object
# passes every check that does not look at it.
for f in FoundationEssentials.o FoundationEssentials.swiftmodule; do
    [ -f "$OUT/$f" ] || { echo "missing $OUT/$f -- run build_fe.sh first" >&2; exit 3; }
    printf "== input  %-34s %10s bytes  %s\n" "$f" \
        "$(stat -c%s "$OUT/$f")" "$(stat -c%y "$OUT/$f" | cut -c1-19)"
done

swiftc -target "$TARGET" -sdk "$SYS" -wmo -O \
    -module-cache-path "$W/scratch/modcache_fe4" \
    -runtime-compatibility-version none \
    -I "$OUT" -I "$W/scratch/fe4_os" -I "$W/scratch/fe4_collections" \
    -Xcc -fmodule-map-file="$W/scratch/swift-foundation/Sources/_FoundationCShims/include/module.modulemap" \
    -Xcc -I"$W/scratch/swift-foundation/Sources/_FoundationCShims/include" \
    -module-name json_runner -emit-object -o "$OUT/json_runner.o" \
    "$J/json_canon.swift" "$J/json_probes.swift" "$J/json_runner.swift"

clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -nostdinc \
    -c -o "$OUT/fm_unimplemented.o" "$W/full/foundation/fm_unimplemented.c"

ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 -syslibroot "$SYS" \
    -rpath /usr/lib/swift -rpath @loader_path -dead_strip \
    -exported_symbol __mh_execute_header \
    -L"$ROOTDIR/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc \
    "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/json_runner" \
    "$OUT/json_runner.o" "$OUT/FoundationEssentials.o" \
    "$W/scratch/fe4_collections/InternalCollectionsUtilities.o" \
    "$W/scratch/fe4_collections/OrderedCollections.o" \
    "$W/scratch/fe4_collections/_RopeModule.o" \
    "$W/scratch/fe4_os/os.o" \
    "$W/scratch/fe4_cshims/platform_shims.o" \
    "$W/scratch/fe4_cshims/string_shims.o" \
    "$W/scratch/fe4_cshims/uuid.o" "$OUT/fm_unimplemented.o" \
    "$@"
echo "== linked $OUT/json_runner"
sha256sum "$OUT/json_runner"

echo "== LC_LOAD_DYLIB vs $ROOTDIR/darwin"
missing=0
llvm-objdump-18 --macho --bind "$OUT/json_runner" | tail -n +4 \
    | awk 'NF>=6 {print $(NF-1)}' | sort | uniq -c > /tmp/json_binds.txt
while read -r path _; do
    case "$path" in /*) ;; *) continue ;; esac
    # objdump prints the bind's dylib as a leaf name with the version letter
    # stripped -- libSystem.B binds appear as `libSystem`.  Matching the raw
    # basename gives those a spurious 0, which reads as "linked and unused" for
    # the libraries every guest needs most.  Try both spellings.
    base=$(basename "$path" .dylib)
    n=$(awk -v b="$base" '$2==b {print $1}' /tmp/json_binds.txt)
    [ -n "$n" ] || n=$(awk -v b="${base%.[AB]}" '$2==b {print $1}' /tmp/json_binds.txt)
    n=${n:-0}
    if [ -f "$ROOTDIR/darwin$path" ]; then
        printf "   ok      %-52s %s non-lazy binds\n" "$path" "$n"
    else
        printf "   MISSING %-52s %s non-lazy binds\n" "$path" "$n"
        missing=$((missing + 1))
    fi
done < <(llvm-objdump-18 --macho --dylibs-used "$OUT/json_runner" | tail -n +2 | awk '{print $1}')
if [ "$missing" -gt 0 ]; then
    echo "== $missing dylib(s) absent from the guest root: this binary LINKS and will NOT LOAD."
    exit 3
fi
echo "== all LC_LOAD_DYLIBs present in the guest root"
