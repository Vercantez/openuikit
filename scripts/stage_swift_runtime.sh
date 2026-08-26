#!/bin/bash
# stage_swift_runtime.sh -- macOS. Assemble scratch/mrroot: a machorun guest
# root that carries the Swift runtime, so a Mach-O Swift guest can RUN.
#
# The Swift runtime dylib the SPIKE said "does not exist as a file" DOES exist,
# as plain arm64 (not arm64e) Mach-O, inside the iOS Simulator runtime -- the
# simulator runs non-PAC arm64. We stage those, plus machorun's own darwin/
# dylibs and the two runtime shims that build_runtime_shims.sh produces:
#   libSystem.B.dylib  = syspatch (47 missing symbols) reexporting the real one
#   libc++.1.dylib     = cxxpatch (5 missing symbols)  reexporting the real one
#   Foundation/CoreFoundation stubs (8 error-bridging symbols libswiftCore imports)
#
# Run build_runtime_shims.sh (in Docker) FIRST -- it writes the shims into
# build/linux and this script copies them in.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only (reads the CoreSimulator runtime)"; exit 1; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MACHORUN=${MACHORUN:-$HOME/machorun}
MR="$ROOT/scratch/mrroot"
OUT="$ROOT/build/linux"

SIM=${SIM:-"/Library/Developer/CoreSimulator/Volumes/iOS_23B80/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.1.simruntime/Contents/Resources/RuntimeRoot/usr/lib/swift"}
[ -f "$SIM/libswiftCore.dylib" ] || { echo "no sim libswiftCore at: $SIM" >&2; exit 1; }
file "$SIM/libswiftCore.dylib" | grep -q arm64 || { echo "sim libswiftCore is not arm64" >&2; exit 1; }
[ -x "$MACHORUN/build/machorun" ] || { echo "build machorun first: $MACHORUN/build/machorun" >&2; exit 1; }

rm -rf "$MR"
mkdir -p "$MR/darwin/usr/lib/swift" \
         "$MR/darwin/System/Library/Frameworks/Foundation.framework" \
         "$MR/darwin/System/Library/Frameworks/CoreFoundation.framework"

# machorun's own userland + loader
cp "$MACHORUN"/darwin/usr/lib/*.dylib "$MR/darwin/usr/lib/"
cp "$MACHORUN/build/machorun" "$MR/machorun"

# the Swift runtime, from the iOS simulator (arm64, non-arm64e)
cp "$SIM/libswiftCore.dylib" "$SIM/libswiftObjectiveC.dylib" "$SIM/libswift_Concurrency.dylib" \
   "$MR/darwin/usr/lib/swift/"
chmod u+w "$MR/darwin/usr/lib/swift/"*.dylib

# the shims (built by build_runtime_shims.sh in Docker)
for f in libSystem.real.dylib libSystem.B.umbrella.dylib \
         libc++.real.dylib libc++.1.umbrella.dylib \
         Foundation.stub.dylib CoreFoundation.stub.dylib; do
    [ -f "$OUT/$f" ] || { echo "missing $OUT/$f -- run build_runtime_shims.sh first" >&2; exit 1; }
done
cp "$OUT/libSystem.real.dylib"        "$MR/darwin/usr/lib/libSystem.real.dylib"
cp "$OUT/libSystem.B.umbrella.dylib"  "$MR/darwin/usr/lib/libSystem.B.dylib"
cp "$OUT/libc++.real.dylib"           "$MR/darwin/usr/lib/libc++.real.dylib"
cp "$OUT/libc++.1.umbrella.dylib"     "$MR/darwin/usr/lib/libc++.1.dylib"
cp "$OUT/Foundation.stub.dylib"       "$MR/darwin/System/Library/Frameworks/Foundation.framework/Foundation"
cp "$OUT/CoreFoundation.stub.dylib"   "$MR/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"

echo "staged guest root: $MR/darwin"
find "$MR/darwin" -type f | sed "s#$MR/##" | sort
