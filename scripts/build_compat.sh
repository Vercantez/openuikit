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

# ------------------------------------------------------------ the NM preflight
# The default NM path exists in the build image and NOT on a macOS host. As
# written, a missing NM makes this script die with exit 127 and "No such file or
# directory" -- safe, but the message names a path and lets the reader think a
# LIBRARY is missing, and the safety rides on errexit propagating out of a
# pipeline inside a for-loop. One `|| true` in a future refactor turns that into
# the failure this whole script exists to prevent: an empty symbol list read as
# "no overlap", which is a green build reporting that it checked nothing.
#
# So the tool is checked by CONTENT, not by existence: it must emit a plausible
# number of symbols for a dylib we know is full of them. A tool that runs and
# prints nothing is exactly as dangerous as one that is absent.
# Empty or non-numeric output must answer "no", not raise a shell error: this
# runs precisely when the tool is broken, so it has to survive a broken tool.
nm_works() {
    local n
    n=$("$1" --defined-only --extern-only "$2" 2>/dev/null | wc -l 2>/dev/null)
    n=${n//[^0-9]/}
    [ -n "$n" ] && [ "$n" -gt 50 ]
}
probe=""
for cand in "$MRLIB/libc++abi.dylib" "$MRLIB/libSystem.B.dylib"; do
  [ -f "$cand" ] && { probe=$cand; break; }
done
if [ -n "$probe" ]; then
  if ! nm_works "$NM" "$probe"; then
    found=""
    for cand in llvm-nm llvm-nm-18 nm; do
      command -v "$cand" >/dev/null 2>&1 && nm_works "$cand" "$probe" && { found=$cand; break; }
    done
    [ -n "$found" ] || {
      echo "REFUSING TO GRADE: no working symbol reader." >&2
      echo "  tried: $NM (the default), then llvm-nm, llvm-nm-18, nm" >&2
      echo "  none listed >50 external symbols in $probe, which is full of them." >&2
      echo "  Set NM=/path/to/nm. An empty symbol list would read as 'no overlap'." >&2
      exit 2
    }
    echo "note: $NM unusable here; grading with '$found' instead" >&2
    NM=$found
  fi
fi

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
