#!/bin/bash
# Build vendor/quartz as /usr/lib/libquartz.dylib -- ON MACOS, with Apple's
# toolchain. This is the ORACLE side of the quartz pixel test.
#
# DARWIN ONLY, ON PURPOSE, for the same reason tests/build_fixtures.sh is:
# the macOS run has to be the real platform compiling and executing the real
# code, or it is not an oracle. Apple's clang, Apple's SDK, Apple's libm.
#
# The two sides of the comparison are therefore:
#
#   macOS   Apple clang + Apple SDK + Apple Libm   -> build/quartz-macos/libquartz.dylib
#   Linux   clang-18 + sdk/ + glibc's libm         -> darwin/usr/lib/libquartz.dylib
#
# from the SAME vendored sources with the SAME language flags. Everything that
# is allowed to differ between them is a deliberate part of the experiment;
# nothing else is. In particular the flags below are copied from
# scripts/build_quartz.sh and any change must be made in both, because a flag
# that differs turns the pixel diff into a measurement of the flag.
#
# INSTALL NAME. /usr/lib/libquartz.dylib is not a file on macOS and never will
# be -- nothing is installed on the oracle host. It is an absolute Darwin path
# so that machorun's prefix map (src/image.c: "it is our tree or an error
# naming the path") picks up darwin/usr/lib/libquartz.dylib on Linux, and on
# macOS dyld is pointed at this build with DYLD_LIBRARY_PATH, which does apply
# leaf-name substitution to absolute install names. Verified 2026-08-26: the
# same fixture that dies with "Library not loaded: /usr/lib/libquartz.dylib"
# runs when DYLD_LIBRARY_PATH names this directory.
#
# The alternative -- an @rpath install name -- was rejected: @rpath resolves
# against the same repository layout on both hosts, so BOTH runs would load the
# same file and the Linux run would silently not be testing the Linux build.
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
    echo "build_quartz_macos.sh: refusing to run on $(uname -s)." >&2
    echo "  This is the oracle side; the Linux side is scripts/build_quartz.sh." >&2
    exit 64
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor/quartz"
OUT="${QUARTZ_MACOS_OUT:-$ROOT/build/quartz-macos}"
OBJ="$OUT/obj"

[ -d "$VENDOR/src" ] || { echo "no vendor/quartz -- scripts/vendor_quartz.sh" >&2; exit 1; }

CXX="$(xcrun -f clang++)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
TARGET="${QUARTZ_MACOS_TARGET:-arm64-apple-macos12}"

# Patches from patches-quartz/ apply to BOTH sides or the comparison is
# meaningless. As of this writing there are none, which is the headline of
# docs/QUARTZ_MACHO.md; the loop is here so that stays true if that changes.
SRC="$OUT/src"
rm -rf "$SRC" "$OBJ"
mkdir -p "$SRC" "$OBJ"
cp -R "$VENDOR/include" "$VENDOR/src" "$VENDOR/third_party" "$SRC/"
npatch=0
for p in "$ROOT"/patches-quartz/*.patch; do
    [ -e "$p" ] || continue
    echo "== patch: $(basename "$p")"
    patch -p1 -d "$SRC" --no-backup-if-mismatch < "$p" >/dev/null
    npatch=$((npatch+1))
done
echo "== patches applied: $npatch"

CXXFLAGS=(-target "$TARGET" -isysroot "$SDK"
          -std=gnu++17 -fno-exceptions -fno-rtti
          -fPIC -Os -g0 -DNDEBUG
          -Wall -Wextra -Wno-unused-parameter -Wno-unused-function
          -I"$SRC/include" -I"$SRC/src" -I"$SRC/third_party")

echo "== compiling with $(basename "$CXX") ($TARGET, $SDK)"
objs=()
for f in "$SRC"/src/*.cpp; do
    o="$OBJ/$(basename "$f" .cpp).o"
    "$CXX" "${CXXFLAGS[@]}" -c "$f" -o "$o" 2>/dev/null
    objs+=("$o")
done
echo "== compiled ${#objs[@]} objects"

"$CXX" -target "$TARGET" -isysroot "$SDK" -dynamiclib \
    -install_name /usr/lib/libquartz.dylib \
    -o "$OUT/libquartz.dylib" "${objs[@]}"

echo "   -> $OUT/libquartz.dylib"
file "$OUT/libquartz.dylib"
