#!/bin/bash
# build_quartz.sh -- runs INSIDE swift-macho-spike:noble. Builds the Swift
# drawing program for arm64-apple-macos as Mach-O: it imports the quartz C
# module (a real Clang module over machorun's libquartz .tbd + headers), draws
# the nine-stage fixture, and writes a PNG. Swift stdlib + Swift->C interop
# (QZRect/QZPoint passed BY VALUE) + the quartz rasteriser, together.
#
# -export_dynamic-style export of __mh_execute_header is required: the syspatch
# _NSGetMachExecuteHeader returns &__mh_execute_header, bound flat to the guest
# exe, and machorun resolves flat lookups only against export tries.
set -euo pipefail
ROOT=/w
SYS=$ROOT/scratch/sysroot
OUT=$ROOT/build/linux
MC=$ROOT/scratch/modcache
mkdir -p "$OUT"

SWIFTC=(swiftc -target arm64-apple-macos11 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -parse-as-library
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 11.0 11.0 -syslibroot "$SYS" -rpath /usr/lib/swift)

echo "== compile quartz_draw.swift (import Quartz)"
"${SWIFTC[@]}" -module-name QuartzDraw -emit-object \
    -o "$OUT/quartz_draw.o" "$ROOT/spike/quartz_draw.swift"

echo "== link libquartzdraw.dylib"
"${LD[@]}" -dylib -install_name @rpath/libquartzdraw.dylib \
    -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    -L/usr/lib -lSystem -lobjc -lquartz \
    -o "$OUT/libquartzdraw.dylib" "$OUT/quartz_draw.o"

echo "== link quartz_main"
clang-18 -target arm64-apple-macos11 -isysroot "$SYS" -O1 -c -o "$OUT/quartz_main.o" "$ROOT/spike/quartz_main.c"
"${LD[@]}" -exported_symbol __mh_execute_header -L/usr/lib -lSystem -rpath @loader_path \
    -o "$OUT/quartz_main" "$OUT/quartz_main.o" "$OUT/libquartzdraw.dylib"

echo "== done"; ls -l "$OUT/quartz_main"
