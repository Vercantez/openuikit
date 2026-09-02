#!/bin/bash
# Build the minimal Foundation slice as a Darwin Mach-O arm64 dylib, on Linux.
#
#   scripts/build_slice.sh
#
# Output: $W/root/darwin/usr/lib/libFoundationSlice.dylib
#
# Install name is /usr/lib/libFoundationSlice.dylib so machorun redirects it
# into $MACHORUN_ROOT/darwin the same way it does libobjc and libSystem.
set -euo pipefail
W=${W:-/work}
R=${R:-/repo}
SDK=$W/sdk/MacOSX.sdk
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
TRIPLE=arm64-apple-macos13.0

mkdir -p "$W/obj" "$W/root/darwin/usr/lib"

# The slice ships as its own clang framework, FoundationSlice.framework, and
# swiftcore-macho's declarations-only Foundation.framework is REMOVED from the
# sysroot. Two clang modules both declaring @interface NSString is a redefinition
# error the moment anything imports both, and the clean-room umbrella has done
# its job already (it existed to compile libswiftCore, which is built).
#
# The Swift module named `Foundation` is the overlay in src/overlay — it
# @_exported imports this clang module and adds the bridging conformances.
rm -rf "$SDK/System/Library/Frameworks/Foundation.framework"
FW=$SDK/System/Library/Frameworks/FoundationSlice.framework
mkdir -p "$FW/Headers" "$FW/Modules"
cp -f "$R/include/FoundationSlice.h" "$FW/Headers/FoundationSlice.h"
cat > "$FW/Modules/module.modulemap" <<'EOF'
framework module FoundationSlice [system] {
  umbrella header "FoundationSlice.h"
  export *
  module * { export * }
}
EOF

echo "==> compiling NSSlice.m"
clang -target $TRIPLE -isysroot "$SDK" \
  -fobjc-runtime=macosx-13.0 -fno-objc-arc \
  -fmodules -fmodules-cache-path="$W/modcache" \
  -I"$R/include" \
  -Wno-objc-root-class -Wno-incompatible-pointer-types -Wno-unused-variable \
  -Os -c "$R/src/slice/NSSlice.m" -o "$W/obj/NSSlice.o"

echo "==> linking libFoundationSlice.dylib"
clang -target $TRIPLE -isysroot "$SDK" \
  -fuse-ld=lld -B "$LLD" -nostdlib -dynamiclib \
  -install_name /usr/lib/libFoundationSlice.dylib \
  -L"$SDK/usr/lib" \
  "$W/obj/NSSlice.o" -lSystem -lobjc \
  -o "$W/root/darwin/usr/lib/libFoundationSlice.dylib"

# The linker needs something to link *against* for the Swift overlay and the
# tests; the dylib itself serves, so also drop a copy where -L can find it.
mkdir -p "$W/lib"
cp -f "$W/root/darwin/usr/lib/libFoundationSlice.dylib" "$W/lib/"

file "$W/lib/libFoundationSlice.dylib"
echo "--- exported classes ---"
llvm-nm-18 -gU "$W/lib/libFoundationSlice.dylib" 2>/dev/null | grep '_OBJC_CLASS_\$_' | sed 's/.*_OBJC_CLASS_\$_/  /' | sort || true
echo "--- exported CF symbols ---"
llvm-nm-18 -gU "$W/lib/libFoundationSlice.dylib" 2>/dev/null | grep -E ' _CF' | sed 's/^/  /' || true
