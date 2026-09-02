#!/bin/bash
# Build the Swift Foundation overlay as a Darwin Mach-O dylib, on Linux.
# The TRIPLE follows the host (foundation-macho/scripts/guest_arch.inc).
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
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/guest_arch.inc"
SDK=$W/sdk/MacOSX.sdk
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}

mkdir -p "$W/obj" "$W/swiftmodule" "$W/root/darwin/usr/lib"

echo "==> compiling Foundation overlay"
# -parse-as-library: no top-level code. -O: avoids needing SwiftOnoneSupport,
# which we did not build (same constraint as swiftcore-macho's run harness).
# -whole-module-optimization is also structural now that the overlay has more
# than one source: it makes swiftc emit the single Foundation.o this link step
# owns. Without it `-c file1 file2 -o Foundation.o` is an invalid request.
swiftc -c -target $TRIPLE -sdk "$SDK" \
  -module-name Foundation -parse-as-library -O -whole-module-optimization \
  -I "$W/swiftmodule" \
  -emit-module -emit-module-path "$W/swiftmodule/Foundation.swiftmodule" \
  "$R/src/overlay/Foundation.swift" "$R/src/overlay/Bundle.swift" \
  -o "$W/obj/Foundation.o"

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
