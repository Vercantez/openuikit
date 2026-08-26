#!/bin/bash
set -euo pipefail
ROOT=/w; SYS=$ROOT/scratch/sysroot; OUT=$ROOT/build/slice; MC=$ROOT/scratch/modcache2
SWIFTCOMPAT=$ROOT/scratch/mrroot/darwin/usr/lib/libswiftcompat.dylib
SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -parse-as-library -wmo
        -Xfrontend -disable-implicit-concurrency-module-import
        -Xfrontend -disable-implicit-string-processing-module-import)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 -syslibroot "$SYS" -rpath /usr/lib/swift)
"${SWIFTC[@]}" -module-name PngProbe -emit-object -o "$OUT/png_probe.o" "$ROOT/slice/probe/png_probe.swift"
# SYSTEM-FIRST link order (mirrors swift_gate ORDER_SYSTEM_FIRST)
"${LD[@]}" -dylib -install_name @rpath/libpngprobe.dylib -L/usr/lib -lSystem -lobjc \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" -o "$OUT/libpngprobe.dylib" "$OUT/png_probe.o"
clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" -O1 -c -o "$OUT/png_probe_main.o" "$ROOT/slice/probe/png_probe_main.c"
"${LD[@]}" -exported_symbol __mh_execute_header -L/usr/lib -lSystem -rpath @loader_path \
    -o "$OUT/png_probe" "$OUT/png_probe_main.o" "$OUT/libpngprobe.dylib"
echo done
