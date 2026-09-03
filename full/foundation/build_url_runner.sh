#!/bin/bash
# build_url_runner.sh -- link the URL oracle runner as an arm64-apple-macos
# Mach-O executable, to run under machorun.
#
# swiftcore-FIRST, for the reason build_full.sh gives: the staged libSystem.tbd
# still advertises swift_*, so a system-first link binds _swift_release into
# libSystem, which no longer defines it, and the guest dies at load.
#
# OUTCOME, STATED UP FRONT: this script LINKS and the binary DOES NOT LOAD.
# It exits 3 and says which four dylibs are missing and how many symbols each
# one is actually needed for.  That is the deliverable -- a measured, named
# blocker -- not a failure to be worked around.  Read the long comment above
# the link line for what was tried and why the obvious escapes are wrong.
#
# CHECK THE ARTIFACT, NOT THE EXIT STATUS, is the whole design of the tail of
# this file: a successful `ld` here means very little, because the load
# commands it writes name libraries that are not in the guest root.
set -euo pipefail
W=${W:-/w}
SYS=${SYS:-$W/scratch/sysroot_fe4}
ROOTDIR=${ROOTDIR:-$W/scratch/mrroot_full}
OUT=${OUT:-$W/scratch/fe4_out}
TARGET=${TARGET:-arm64-apple-macos15.0}
LINK_ARCH=${TARGET%%-*}
mkdir -p "$OUT"

swiftc -target "$TARGET" -sdk "$SYS" -wmo \
    -module-cache-path "$W/scratch/modcache_fe4" \
    -runtime-compatibility-version none \
    -I "$OUT" -I "$W/scratch/fe4_os" -I "$W/scratch/fe4_collections" \
    -Xcc -fmodule-map-file="$W/scratch/swift-foundation/Sources/_FoundationCShims/include/module.modulemap" \
    -Xcc -I"$W/scratch/swift-foundation/Sources/_FoundationCShims/include" \
    -module-name url_runner -emit-object -o "$OUT/url_runner.o" \
    "$W/full/oracle-url/url_runner.swift"

# The 36 symbols machorun's libSystem does not export.  See that file: it does
# not make FileManager work, it makes the binary loadable and makes any call
# into the gap die naming itself.
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -nostdinc \
    -c -o "$OUT/fm_unimplemented.o" "$W/full/foundation/fm_unimplemented.c"

# THIS LINKS AND THE RESULT DOES NOT LOAD, and the reason is worth reading
# before anyone tries to make it load.  machorun says:
#
#   machorun: cannot find dylib '/usr/lib/swift/libswift_StringProcessing.dylib'
#     required by: ./url_runner
#
# and it is right -- that file is not on disk on Linux and (machorun measured
# this) not on disk on macOS either; it lives in the dyld shared cache.  Four
# dylibs are in that position: libswift_StringProcessing, libswiftSynchronization,
# libswift_errno, libswiftDarwin.
#
# THE OBVIOUS ESCAPE WAS TRIED AND IT IS WRONG.  Passing
# `--ignore-auto-link-option=` for the four drops the LC_LOAD_DYLIBs, and the
# link then fails with real undefined symbols: -dead_strip runs AFTER
# resolution, so "dead-stripped" never meant "unreferenced".  Counting the
# actual binds settles it -- `llvm-objdump --macho --bind`, grouped by dylib:
#
#     1532 libswiftCore     83 libobjc                4 libSystem
#       12 libswift_StringProcessing
#        4 libswift_errno
#        1 libswiftSynchronization
#        0 libswiftDarwin
#
# SEVENTEEN symbols, and every one of them is METADATA, not a function:
# `nominal type descriptor for _StringProcessing.Regex`, `type metadata for
# Synchronization._Atomic64BitStorage`, `protocol conformance descriptor for
# Darwin.POSIXErrorCode : Swift.Hashable`.  So the fm_unimplemented.c trick --
# define it, abort loudly if called -- CANNOT be repeated here: nothing calls
# these, the Swift runtime READS them, and a stub would hand it a structure to
# walk.  That is the one shape this project has been most careful never to
# ship.
#
# So the Mach-O guest route is blocked on three real cross-built Swift runtime
# dylibs (libswiftDarwin needs zero symbols and could be an empty stub), the
# same class of artifact as libswiftCore.dylib and libswift_Concurrency.dylib,
# which ~/swiftcore-macho already produces and which
# machorun/scripts/stage_swiftcore.sh already knows how to stage.  Its
# artifacts/ holds neither today.  Bounded work in a repo that has done it
# twice -- not a new problem.
ld64.lld-18 -arch "$LINK_ARCH" -platform_version macos 15.0 15.0 -syslibroot "$SYS" \
    -rpath /usr/lib/swift -rpath @loader_path -dead_strip \
    -exported_symbol __mh_execute_header \
    -L"$ROOTDIR/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc \
    "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/url_runner" \
    "$OUT/url_runner.o" "$OUT/FoundationEssentials.o" \
    "$W/scratch/fe4_collections/InternalCollectionsUtilities.o" \
    "$W/scratch/fe4_collections/OrderedCollections.o" \
    "$W/scratch/fe4_collections/_RopeModule.o" \
    "$W/scratch/fe4_os/os.o" \
    "$W/scratch/fe4_cshims/platform_shims.o" \
    "$W/scratch/fe4_cshims/string_shims.o" \
    "$W/scratch/fe4_cshims/uuid.o" "$OUT/fm_unimplemented.o" \
    "$@"
echo "== linked $OUT/url_runner"
# SAY WHETHER IT CAN LOAD (the count is NON-LAZY binds only -- libSystem shows
# 4 while the objects reference ~130 libc names, because the rest bind lazily;
# it is there to separate "absent and unused" from "absent and needed", not as
# an import total), rather than leaving a successful link to be read as
# a working binary.  Every LC_LOAD_DYLIB is checked against the guest root the
# binary will actually run in; a missing one is printed with the count of
# symbols bound against it, so "absent and unused" and "absent and needed" are
# never the same line.
echo "== LC_LOAD_DYLIB vs $ROOTDIR/darwin"
missing=0
llvm-objdump-18 --macho --bind "$OUT/url_runner" | tail -n +4 \
    | awk 'NF>=6 {print $(NF-1)}' | sort | uniq -c > /tmp/binds.txt
while read -r path _; do
    case "$path" in /*) ;; *) continue ;; esac
    # objdump prints the bind's dylib as a leaf name with the version letter
    # stripped -- libSystem.B.dylib binds appear as `libSystem`, libobjc.A as
    # `libobjc`.  Matching the raw basename gives those two a spurious 0,
    # which reads as "linked and unused" for the two libraries every guest
    # needs most.  Try both spellings.
    base=$(basename "$path" .dylib)
    n=$(awk -v b="$base" '$2==b {print $1}' /tmp/binds.txt)
    [ -n "$n" ] || n=$(awk -v b="${base%.[AB]}" '$2==b {print $1}' /tmp/binds.txt)
    n=${n:-0}
    if [ -f "$ROOTDIR/darwin$path" ]; then
        printf "   ok      %-52s %s non-lazy binds\n" "$path" "$n"
    else
        printf "   MISSING %-52s %s non-lazy binds\n" "$path" "$n"
        missing=$((missing + 1))
    fi
done < <(llvm-objdump-18 --macho --dylibs-used "$OUT/url_runner" | tail -n +2 | awk '{print $1}')
if [ "$missing" -gt 0 ]; then
    echo "== $missing dylib(s) absent from the guest root: this binary LINKS and will NOT LOAD."
    exit 3
fi
echo "== all LC_LOAD_DYLIBs present in the guest root"
