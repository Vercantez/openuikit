#!/bin/bash
# build_slice.sh -- runs INSIDE swift-macho-spike:noble. Builds a vendored slice
# of OpenUIKit (OpenCoreGraphics + minimal UIView stack) for arm64-apple-macos
# as a Mach-O dylib, against the staged Swift runtime + Quartz module.
set -euo pipefail
ROOT=/w
SYS=$ROOT/scratch/sysroot
OUT=$ROOT/build/slice
MC=$ROOT/scratch/modcache
mkdir -p "$OUT"

SWIFTC=(swiftc -target arm64-apple-macos11 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -parse-as-library -wmo
       
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 11.0 11.0 -syslibroot "$SYS" -rpath /usr/lib/swift)

SRCS=("$ROOT"/slice/src/*.swift)

echo "== compile UIKitSlice module (${#SRCS[@]} files)"
"${SWIFTC[@]}" -module-name UIKitSlice -emit-object -emit-module \
    -emit-module-path "$OUT/UIKitSlice.swiftmodule" \
    -o "$OUT/uikitslice.o" "${SRCS[@]}"

echo "== link libuikitslice.dylib"
# libSystemSwiftShim.tbd advertises _pthread_main_np (added to the syspatch
# libSystem umbrella) so the MainActor executor thunk binds two-level to
# /usr/lib/libSystem.B.dylib instead of failing the link.
"${LD[@]}" -dylib -install_name @rpath/libuikitslice.dylib \
    -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    -L/usr/lib -lSystem -lobjc -lquartz \
    "$ROOT/slice/libSystemSwiftShim.tbd" \
    -o "$OUT/libuikitslice.dylib" "$OUT/uikitslice.o"

echo "== compile boxes_render.swift (import UIKitSlice)"
"${SWIFTC[@]}" -I "$OUT" -module-name SliceBoxes -emit-object \
    -o "$OUT/boxes_render.o" "$ROOT/slice/boxes_render.swift"

echo "== link libsliceboxes.dylib"
"${LD[@]}" -dylib -install_name @rpath/libsliceboxes.dylib \
    -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
    -L/usr/lib -lSystem -lobjc -lquartz \
    -L"$OUT" -luikitslice \
    "$ROOT/slice/libSystemSwiftShim.tbd" \
    -o "$OUT/libsliceboxes.dylib" "$OUT/boxes_render.o"

echo "== link slice_main"
clang-18 -target arm64-apple-macos11 -isysroot "$SYS" -O1 -c -o "$OUT/slice_main.o" "$ROOT/slice/slice_main.c"
"${LD[@]}" -exported_symbol __mh_execute_header -L/usr/lib -lSystem -rpath @loader_path \
    -o "$OUT/slice_main" "$OUT/slice_main.o" "$OUT/libsliceboxes.dylib" "$OUT/libuikitslice.dylib"

echo "== done"; ls -l "$OUT"/slice_main "$OUT"/*.dylib
