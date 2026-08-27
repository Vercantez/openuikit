#!/bin/bash
# Build libswiftcompat.dylib -- the gap between our cross-built libswiftCore /
# libswift_Concurrency and machorun's self-hosted Darwin userland.
# See sdk/compat/swiftcompat.c for what is in it and why.
#
# Runs anywhere with swift.org's clang for the compile and Ubuntu's ld64.lld for
# the link. scripts/build_compat_docker.sh drives it locally in the
# machorun-swift:6.2.4 image; no AWS box is needed for this artefact.
#
# THE ASSERTION AT THE BOTTOM IS THE POINT OF THIS SCRIPT.
#
# This shim exists to fill a gap, and a gap shrinks. Every time machorun's
# userland grows a real implementation, the corresponding definition here stops
# being a fill and becomes a DUPLICATE -- and libswiftCore binds most of these
# flat, so a duplicate is resolved by load order, not by which one is correct.
# On 2026-08-27 ten symbols had already crossed that line without anyone
# noticing, including a pthread_main_np that returned a constant 1.
#
# So the build refuses to emit a dylib whose exports intersect machorun's. It
# is not a warning: a shim that overlaps is a loaded gun, and the failure it
# eventually produces (a jump through a zerofill vtable during exception
# dispatch, say) is nowhere near the cause.
set -euo pipefail

W=${W:-$HOME/work}
SDK=${SDK:-$W/sdk/MacOSX.sdk}
TC=${TC:-/opt/swift624/usr}
SRC=${SRC:-$W/compat}
# machorun's built userland -- the thing we must not collide with.
MRLIB=${MRLIB:-$W/machorun/darwin/usr/lib}
OUT=${OUT:-$MRLIB/libswiftcompat.dylib}
NM=${NM:-/usr/lib/llvm-18/bin/llvm-nm}
LLD_BIN=${LLD_BIN:-/usr/lib/llvm-18/bin}

CC="$TC/bin/clang"; CXX="$TC/bin/clang++"
[ -x "$CC" ] || { CC=clang; CXX=clang++; }   # image installs it on PATH

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$(dirname "$OUT")"

"$CC" -target arm64-apple-macos13.0 -isysroot "$SDK" -O1 -fPIC \
  -Wno-incompatible-library-redeclaration -Wno-builtin-requires-header \
  -c "$SRC/swiftcompat.c" -o "$tmp/swiftcompat.o"

"$CXX" -target arm64-apple-macos13.0 -isysroot "$SDK" -O1 -fPIC -std=c++17 \
  -fno-exceptions -fno-rtti \
  -c "$SRC/shim.cpp" -o "$tmp/shim.o"

"$CXX" -target arm64-apple-macos13.0 -isysroot "$SDK" \
  -fuse-ld=lld -B "$LLD_BIN" \
  -dynamiclib -install_name /usr/lib/libswiftcompat.dylib \
  -compatibility_version 1 -current_version 1 \
  -nostdlib -L"$SDK/usr/lib" \
  "$tmp/swiftcompat.o" "$tmp/shim.o" \
  -lSystem -lc++ \
  -Wl,-undefined,dynamic_lookup \
  -o "$tmp/libswiftcompat.dylib"

"$NM" --defined-only --extern-only "$tmp/libswiftcompat.dylib" \
  | awk '{print $NF}' | sort -u > "$tmp/shim_exports.txt"

# ------------------------------------------------ the disjointness assertion
# Union of everything machorun's userland exports. Note this reads the BUILT
# dylibs, not the .tbds: a .tbd is generated from a dylib and can lag it, and
# what decides a flat bind at runtime is the dylib.
: > "$tmp/userland.txt"
for lib in libSystem.B.dylib libobjc.A.dylib libc++.1.dylib libc++abi.dylib; do
  [ -f "$MRLIB/$lib" ] || continue
  "$NM" --defined-only --extern-only "$MRLIB/$lib" | awk '{print $NF}'
done | sort -u > "$tmp/userland.txt"

if [ ! -s "$tmp/userland.txt" ]; then
  echo "REFUSING TO GRADE: no machorun dylibs found under $MRLIB." >&2
  echo "The overlap check would pass vacuously, which is worse than not running it." >&2
  exit 2
fi

overlap=$(comm -12 "$tmp/shim_exports.txt" "$tmp/userland.txt")
if [ -n "$overlap" ]; then
  echo >&2
  echo "BUILD REFUSED: libswiftcompat defines $(printf '%s\n' "$overlap" | wc -l) symbol(s) machorun's userland already defines." >&2
  echo >&2
  printf '%s\n' "$overlap" | while read -r s; do
    where=$(for lib in libSystem.B.dylib libobjc.A.dylib libc++.1.dylib libc++abi.dylib; do
              [ -f "$MRLIB/$lib" ] && "$NM" --defined-only --extern-only "$MRLIB/$lib" \
                | awk -v s="$s" -v l="$lib" '$NF==s {print l}'
            done | tr '\n' ' ')
    printf '    %-52s already in: %s\n' "$s" "$where" >&2
  done
  echo >&2
  echo "DELETE them from sdk/compat/swiftcompat.c -- do not correct them in two" >&2
  echo "places. libswiftCore binds these flat, so the winner is decided by load" >&2
  echo "order rather than by which definition is right." >&2
  exit 1
fi

install -m 0755 "$tmp/libswiftcompat.dylib" "$OUT"
echo "built:   $OUT  ($(wc -c < "$OUT") bytes)"
echo "exports: $(wc -l < "$tmp/shim_exports.txt")  -- disjoint from machorun's $(wc -l < "$tmp/userland.txt")-symbol userland"
