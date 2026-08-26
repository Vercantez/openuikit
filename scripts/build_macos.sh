#!/bin/bash
# build_macos.sh -- THE ORACLE. macOS only: Apple swiftc, Apple ld, Apple SDK,
# run natively. The Linux side never writes into build/macos.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/build/macos
mkdir -p "$OUT"

xcrun swiftc -target arm64-apple-macos11 -parse-as-library -emit-library \
    -module-name Spike -o "$OUT/libspike.dylib" "$ROOT/spike/libspike.swift" \
    -Xlinker -install_name -Xlinker @rpath/libspike.dylib
xcrun clang -target arm64-apple-macos11 -O1 -o "$OUT/spike_main" \
    "$ROOT/spike/spike_main.c" "$OUT/libspike.dylib" -Wl,-rpath,@loader_path

xcrun swiftc -target arm64-apple-macos11 -parse-as-library -emit-library \
    -module-name SpikeObjC -Xfrontend -disable-objc-attr-requires-foundation-module \
    -o "$OUT/libobjcprobe.dylib" "$ROOT/spike/objc_probe.swift" \
    -Xlinker -install_name -Xlinker @rpath/libobjcprobe.dylib
xcrun clang -target arm64-apple-macos11 -O1 -o "$OUT/objc_main" \
    "$ROOT/spike/objc_main.c" "$OUT/libobjcprobe.dylib" -Wl,-rpath,@loader_path
ls -l "$OUT"

xcrun swiftc -target arm64-apple-macos11 -parse-as-library -emit-library \
    -module-name Breadth -Xfrontend -disable-objc-attr-requires-foundation-module \
    -o "$OUT/libbreadth.dylib" "$ROOT/spike/breadth.swift" \
    -Xlinker -install_name -Xlinker @rpath/libbreadth.dylib
xcrun clang -target arm64-apple-macos11 -O1 -o "$OUT/breadth_main" \
    "$ROOT/spike/breadth_main.c" "$OUT/libbreadth.dylib" -Wl,-rpath,@loader_path
