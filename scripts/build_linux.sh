#!/bin/bash
# build_linux.sh -- runs INSIDE swift-macho-spike:noble. Builds every spike
# artifact for arm64-apple-macos with no Apple tool in the loop:
#   swiftc (Linux 6.2.4)  -> Mach-O object, Darwin stdlib from scratch/sysroot
#   clang-18              -> Mach-O object from C, headers from scratch/sysroot
#   ld64.lld-18           -> Mach-O dylib + Mach-O executable
#
# -module-name is spelled out because the Apple driver derives it from the
# output filename and this one would derive it from the source filename; the
# mangled class name differs for that reason alone otherwise.
set -euo pipefail
ROOT=/w
SYS=$ROOT/scratch/sysroot
OUT=$ROOT/build/linux
MC=$ROOT/scratch/modcache
mkdir -p "$OUT"

SWIFTC=(swiftc -target arm64-apple-macos11 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -parse-as-library)
# -rpath /usr/lib/swift matches what Apple's driver emits: the Darwin .tbds
# for libswift_Concurrency and friends carry @rpath install names, and the
# rpath is what turns those back into absolute Darwin paths.
# LIBRARY ORDER IS LOAD-BEARING, and not for the usual reason. machorun's
# libSystem.B.dylib exports _swift_retain / _swift_release -- the loud-abort
# stubs of docs/UNIMPLEMENTED.md#swift-interop -- and its .tbd advertises them.
# Mach-O two-level namespace records the FIRST dylib on the line that exports a
# symbol, so -lSystem before -lswiftCore silently binds Swift's own retain to
# libSystem. On macOS that binds to nothing and the lazy stub jumps to 0.
LD=(ld64.lld-18 -arch arm64 -platform_version macos 11.0 11.0 -syslibroot "$SYS" -rpath /usr/lib/swift)

# ---------------------------------------------------------------- rung 1 + 2
# -lobjc is not optional even though this file has no @objc in it: a
# Darwin-targeted Swift image always emits __objc_imageinfo, and machorun
# aborts with UNIMPLEMENTED: objc-callbacks if nothing pulls libobjc in.
echo "== libspike.dylib"
"${SWIFTC[@]}" -module-name Spike -emit-object -o "$OUT/libspike.o" "$ROOT/spike/libspike.swift"
"${LD[@]}" -dylib -install_name @rpath/libspike.dylib -L/usr/lib -lSystem -lobjc \
    -o "$OUT/libspike.dylib" "$OUT/libspike.o"

echo "== spike_main"
clang-18 -target arm64-apple-macos11 -isysroot "$SYS" -O1 -c -o "$OUT/spike_main.o" "$ROOT/spike/spike_main.c"
"${LD[@]}" -L/usr/lib -lSystem -rpath @loader_path -o "$OUT/spike_main" "$OUT/spike_main.o" "$OUT/libspike.dylib"

# ---------------------------------------------------------------- rung 4
echo "== libobjcprobe.dylib (@objc + #selector)"
"${SWIFTC[@]}" -module-name SpikeObjC -Xfrontend -disable-objc-attr-requires-foundation-module \
    -emit-object -o "$OUT/objc_probe.o" "$ROOT/spike/objc_probe.swift"
"${LD[@]}" -dylib -install_name @rpath/libobjcprobe.dylib \
    -L/usr/lib/swift -lswiftCore -lswiftObjectiveC -L/usr/lib -lSystem -lobjc \
    -o "$OUT/libobjcprobe.dylib" "$OUT/objc_probe.o"

echo "== objc_main"
clang-18 -target arm64-apple-macos11 -isysroot "$SYS" -O1 -c -o "$OUT/objc_main.o" "$ROOT/spike/objc_main.c"
"${LD[@]}" -L/usr/lib -lSystem -rpath @loader_path -o "$OUT/objc_main" "$OUT/objc_main.o" "$OUT/libobjcprobe.dylib"


# ---------------------------------------------------------------- breadth
echo "== libbreadth.dylib (protocols, generics, closures, collections, async)"
"${SWIFTC[@]}" -module-name Breadth -Xfrontend -disable-objc-attr-requires-foundation-module \
    -emit-object -o "$OUT/breadth.o" "$ROOT/spike/breadth.swift"
"${LD[@]}" -dylib -install_name @rpath/libbreadth.dylib \
    -L/usr/lib/swift -lswiftCore -lswiftObjectiveC -lswift_Concurrency -L/usr/lib -lSystem -lobjc \
    -o "$OUT/libbreadth.dylib" "$OUT/breadth.o"
clang-18 -target arm64-apple-macos11 -isysroot "$SYS" -O1 -c -o "$OUT/breadth_main.o" "$ROOT/spike/breadth_main.c"
"${LD[@]}" -L/usr/lib -lSystem -rpath @loader_path -o "$OUT/breadth_main" "$OUT/breadth_main.o" "$OUT/libbreadth.dylib"

echo "== done"; ls -l "$OUT"
