#!/bin/bash
# build_slice3.sh -- build the OpenUIKit slice against swiftcore-build's
# SELF-BUILT core-only libswiftCore, compiling with ITS resource-dir (swift-res)
# the way machorun's swift_gate.sh does -- not the Xcode sysroot interfaces
# (build_slice2.sh's ABI mismatch faults in swift_unknownObjectRetain). SDK is
# machorun's own header-only SDK augmented with the quartz + ObjectiveC modules.
set -euo pipefail
ROOT=/w
SDK=$ROOT/scratch/mrsdk                # machorun header-only SDK (+ quartz/objc)
OUT=$ROOT/build/slice3
COMPAT=$ROOT/scratch/mrroot2/darwin/usr/lib/libswiftcompat.dylib
mkdir -p "$OUT"

# Resource dir = the self-built stdlib's Swift.swiftmodule/dylib + the compiler's
# own shims (SwiftShims must match the swiftc doing the compile).
RES=/tmp/res; rm -rf "$RES"; cp -a "$ROOT/scratch/swift-res" "$RES"
cp -a /usr/lib/swift/shims "$RES/shims"

SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SDK" -resource-dir "$RES" -O
        -parse-as-library -wmo
        -Xfrontend -disable-implicit-concurrency-module-import
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module
        -Xcc -isystem -Xcc /usr/lib/llvm-18/lib/clang/18/include)
# clang link, gate-style: lld emitting Mach-O, core-only Darwin libs named out.
LINK() { clang-18 -target arm64-apple-macos13.0 -isysroot "$SDK" \
        -fuse-ld=lld -B /usr/lib/llvm-18/bin -nostdlib \
        -L"$SDK/usr/lib" -L"$RES/macosx/arm64" -rpath /usr/lib/swift "$@"; }

echo "== compile UIKitSlice module (self-built core resource-dir)"
"${SWIFTC[@]}" -module-name UIKitSlice -emit-object -emit-module \
    -emit-module-path "$OUT/UIKitSlice.swiftmodule" \
    -o "$OUT/uikitslice.o" "$ROOT"/slice/src/*.swift

echo "== link libuikitslice.dylib"
LINK -shared -Wl,-install_name,@rpath/libuikitslice.dylib \
    "$OUT/uikitslice.o" -lswiftCore "$COMPAT" -lSystem -lobjc -lquartz \
    -o "$OUT/libuikitslice.dylib"

echo "== compile boxes_render.swift"
"${SWIFTC[@]}" -I "$OUT" -module-name SliceBoxes -emit-object \
    -o "$OUT/boxes_render.o" "$ROOT/slice/boxes_render.swift"

echo "== link libsliceboxes.dylib"
LINK -shared -Wl,-install_name,@rpath/libsliceboxes.dylib \
    "$OUT/boxes_render.o" -L"$OUT" -luikitslice \
    -lswiftCore "$COMPAT" -lSystem -lobjc -lquartz \
    -o "$OUT/libsliceboxes.dylib"

echo "== link slice_main"
clang-18 -target arm64-apple-macos13.0 -isysroot "$SDK" -O1 -c -o "$OUT/slice_main.o" "$ROOT/slice/slice_main.c"
LINK -Wl,-exported_symbol,__mh_execute_header -rpath @loader_path \
    "$OUT/slice_main.o" "$OUT/libsliceboxes.dylib" "$OUT/libuikitslice.dylib" \
    -lSystem -o "$OUT/slice_main"

echo "== done"; ls -l "$OUT"/slice_main "$OUT"/*.dylib
