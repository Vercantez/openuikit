#!/bin/bash
# build_slice2.sh -- like build_slice.sh but targets the SELF-BUILT, CORE-ONLY
# libswiftCore (~/swiftcore-macho, macOS arm64) that machorun's swift_gate.sh
# validated. That runtime has no _Concurrency / _StringProcessing / ObjectiveC
# overlay, so the implicit imports are disabled and the link is core-only plus
# libswiftcompat.dylib (its 29 userland-gap symbols), mirroring the gate's line.
set -euo pipefail
ROOT=/w

# This script READS a guest root it does not build. A copy read long after it was
# made is indistinguishable from a fresh one -- four such roots were found still
# carrying a malloc_type bug fixed upstream weeks earlier. Refuse rather than
# silently test the past. MRROOT_REFRESH=1 to update instead.
"$(dirname "${BASH_SOURCE[0]}")/require_fresh_root.sh" scratch/mrroot || exit 1

SYS=$ROOT/scratch/sysroot
OUT=$ROOT/build/slice
MC=$ROOT/scratch/modcache2
SWIFTCOMPAT=$ROOT/scratch/mrroot/darwin/usr/lib/libswiftcompat.dylib
mkdir -p "$OUT"

SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -parse-as-library -wmo
        -Xfrontend -disable-implicit-concurrency-module-import
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 -syslibroot "$SYS" -rpath /usr/lib/swift)

SRCS=("$ROOT"/slice/src/*.swift)

echo "== compile UIKitSlice module (core-only)"
"${SWIFTC[@]}" -module-name UIKitSlice -emit-object -emit-module \
    -emit-module-path "$OUT/UIKitSlice.swiftmodule" \
    -o "$OUT/uikitslice.o" "${SRCS[@]}"

echo "== link libuikitslice.dylib (core-only + libswiftcompat)"
"${LD[@]}" -dylib -install_name @rpath/libuikitslice.dylib \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc -lquartz \
    -o "$OUT/libuikitslice.dylib" "$OUT/uikitslice.o"

echo "== compile boxes_render.swift"
"${SWIFTC[@]}" -I "$OUT" -module-name SliceBoxes -emit-object \
    -o "$OUT/boxes_render.o" "$ROOT/slice/boxes_render.swift"

echo "== link libsliceboxes.dylib"
"${LD[@]}" -dylib -install_name @rpath/libsliceboxes.dylib \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc -lquartz \
    -L"$OUT" -luikitslice \
    -o "$OUT/libsliceboxes.dylib" "$OUT/boxes_render.o"

echo "== link slice_main"
clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" -O1 -c -o "$OUT/slice_main.o" "$ROOT/slice/slice_main.c"
"${LD[@]}" -exported_symbol __mh_execute_header -L/usr/lib -lSystem -rpath @loader_path \
    -o "$OUT/slice_main" "$OUT/slice_main.o" "$OUT/libsliceboxes.dylib" "$OUT/libuikitslice.dylib"

echo "== done"; ls -l "$OUT"/slice_main "$OUT"/*.dylib