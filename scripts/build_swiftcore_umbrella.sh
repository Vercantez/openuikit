#!/bin/bash
# build_swiftcore_umbrella.sh -- runs INSIDE swift-macho-spike:noble. Wraps the
# staged iOS-simulator libswiftCore.dylib in an umbrella that adds the handful
# of symbols the sysroot .tbd advertises but this runtime build lacks (version
# skew; see spike/swiftcorepatch.c). Idempotent: refuses to double-wrap.
set -euo pipefail
ROOT=/w
SYS=$ROOT/scratch/sysroot
SWDIR=$ROOT/scratch/mrroot/darwin/usr/lib/swift
OUT=$ROOT/build/linux
# The staged libswiftCore is an iOS-SIMULATOR-platform image; ld64.lld refuses
# to LC_REEXPORT_DYLIB it into a macOS umbrella, so the umbrella (and its patch
# object) are built for the ios-simulator platform to match. This only affects
# the umbrella's own load command; machorun loads it by install name and the
# slice links against the macOS sysroot tbd, not this file.
CC=(clang-18 -target arm64-apple-ios26.0-simulator -isysroot "$SYS")
LD=(ld64.lld-18 -arch arm64 -platform_version ios-simulator 26.0 26.0 -syslibroot "$SYS")

# The real gets a distinct, SAME-LENGTH identity so the umbrella can reexport
# it. llvm-install-name-tool-18 can't rewrite the sim dylib (chained fixups), so
# a byte-in-place LC_ID_DYLIB edit is used: libswiftCore.dylib -> libswiftCor.dylib.
# libswiftCor.dylib is the REAL (>1MB). Guard against ever reexporting a stale
# umbrella copy of itself.
# Source of truth for the REAL runtime is scratch/real/libswiftCore.sim.dylib
# (staged host-side, well before this runs -- avoids the Docker-for-Mac
# bind-mount write-then-read race that clobbers in-place edits). Everything
# below reads/writes container-side within one exec, so it stays consistent.
REAL="$SWDIR/libswiftCor.dylib"
PRISTINE="$ROOT/scratch/real/libswiftCore.sim.dylib"
[ -f "$PRISTINE" ] || { echo "ERROR: stage scratch/real/libswiftCore.sim.dylib first (host: cp from the sim runtime)"; exit 1; }
cp "$PRISTINE" "$REAL"
perl "$ROOT/scripts/set_id_dylib.pl" "$REAL" /usr/lib/swift/libswiftCor.dylib

"${CC[@]}" -O1 -c -o "$OUT/swiftcorepatch.o" "$ROOT/spike/swiftcorepatch.c"
"${LD[@]}" -dylib -install_name /usr/lib/swift/libswiftCore.dylib -undefined dynamic_lookup \
    -o "$OUT/libswiftCore.umbrella.dylib" "$OUT/swiftcorepatch.o" \
    -reexport_library "$REAL"
cp "$OUT/libswiftCore.umbrella.dylib" "$SWDIR/libswiftCore.dylib"
echo "staged libswiftCore umbrella into $SWDIR"
ls -l "$SWDIR"/libswiftCor.dylib "$SWDIR"/libswiftCore.dylib
