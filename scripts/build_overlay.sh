#!/bin/bash
# Build the Swift Foundation overlay as a Darwin Mach-O arm64 dylib, on Linux.
#
#   scripts/build_overlay.sh
#
# Outputs:
#   $W/root/darwin/usr/lib/libFoundation.dylib
#   $W/swiftmodule/Foundation.swiftmodule
#
# The overlay is a Swift module named `Foundation` that @_exported imports the
# clang module `FoundationSlice` and adds the _ObjectiveCBridgeable conformances
# libswiftCore deliberately does not ship. See src/overlay/Foundation.swift.
set -euo pipefail
W=${W:-/work}
R=${R:-/repo}
SDK=$W/sdk/MacOSX.sdk
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
TRIPLE=arm64-apple-macos13.0

mkdir -p "$W/obj" "$W/swiftmodule" "$W/root/darwin/usr/lib"

echo "==> compiling Foundation overlay"
# -parse-as-library: no top-level code. -O: avoids needing SwiftOnoneSupport,
# which we did not build (same constraint as swiftcore-macho's run harness).
swiftc -c -target $TRIPLE -sdk "$SDK" \
  -module-name Foundation -parse-as-library -O \
  -I "$W/swiftmodule" \
  -emit-module -emit-module-path "$W/swiftmodule/Foundation.swiftmodule" \
  "$R/src/overlay/Foundation.swift" -o "$W/obj/Foundation.o"

echo "==> linking libFoundation.dylib"
# -lswiftCore BEFORE -lSystem: machorun binds flat in load order and its
# libSystem exports a swift_release diagnostic stub that otherwise shadows the
# real one. Documented in ~/swiftcore-macho/scripts/run_under_machorun.sh.
clang -target $TRIPLE -isysroot "$SDK" \
  -fuse-ld=lld -B "$LLD" -nostdlib -dynamiclib \
  -install_name /usr/lib/libFoundation.dylib \
  -L"$SDK/usr/lib" -L"$W/lib" \
  "$W/obj/Foundation.o" \
  -lswiftCore -lFoundationSlice "$W/lib/libswiftcompat.dylib" -lSystem -lobjc \
  -o "$W/root/darwin/usr/lib/libFoundation.dylib"

cp -f "$W/root/darwin/usr/lib/libFoundation.dylib" "$W/lib/"
file "$W/lib/libFoundation.dylib"
