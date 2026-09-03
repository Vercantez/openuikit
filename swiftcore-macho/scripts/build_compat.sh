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
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

W=${W:-$HOME/work}
SDK=${SDK:-$W/sdk/MacOSX.sdk}
# TC already set by guest_arch.inc (SWIFT_TOOLCHAIN, PATH, /opt/swift624/usr, or /usr).
SRC=${SRC:-$W/compat}
# machorun's built userland -- the thing we must not collide with.
MRLIB=${MRLIB:-$W/machorun/darwin/usr/lib}
# The loader counts as userland. In machorun the loader IS dyld, so its 99
# exports are the dyld surface and live in no dylib. A shim symbol colliding
# with one of those is the same defect as colliding with libSystem's, and this
# assertion could not see it until 2026-08-27.
LOADER=${LOADER:-$W/machorun/build/machorun}
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

"$CC" -target "$SWIFTCORE_CLANG_TARGET" -isysroot "$SDK" -O1 -fPIC \
  -Wno-incompatible-library-redeclaration -Wno-builtin-requires-header \
  -c "$SRC/swiftcompat.c" -o "$tmp/swiftcompat.o"

"$CXX" -target "$SWIFTCORE_CLANG_TARGET" -isysroot "$SDK" -O1 -fPIC -std=c++17 \
  -fno-exceptions -fno-rtti \
  -c "$SRC/shim.cpp" -o "$tmp/shim.o"

# x86-only: unexport the nine symbols x86 libSystem already defines. The
# arm64 staged libSystem (scratch/mrroot_full, scratch/sysroot_fe4) exports
# none of them, so the committed arm64 artifacts/libswiftcompat.dylib must
# keep them. Do not delete them from swiftcompat.c. List:
# sdk/compat/x86_unexported_symbols.txt
unexport=()
case "$SWIFTCORE_CLANG_TARGET" in
  x86_64-*)
    unexport_list=$SCRIPT_DIR/../sdk/compat/x86_unexported_symbols.txt
    [ -f "$unexport_list" ] || {
      echo "build_compat: missing $unexport_list" >&2
      exit 2
    }
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case "$s" in \#*) continue ;; esac
      unexport+=(-Wl,-unexported_symbol,"$s")
    done < "$unexport_list"
    ;;
esac

"$CXX" -target "$SWIFTCORE_CLANG_TARGET" -isysroot "$SDK" \
  -fuse-ld=lld -B "$LLD_BIN" \
  -dynamiclib -install_name /usr/lib/libswiftcompat.dylib \
  -compatibility_version 1 -current_version 1 \
  -nostdlib -L"$SDK/usr/lib" \
  "$tmp/swiftcompat.o" "$tmp/shim.o" \
  -lSystem -lc++ \
  -Wl,-undefined,dynamic_lookup \
  "${unexport[@]}" \
  -o "$tmp/libswiftcompat.dylib"

"$NM" --defined-only --extern-only "$tmp/libswiftcompat.dylib" \
  | awk '{print $NF}' | sort -u > "$tmp/shim_exports.txt"

# ------------------------------------------------ the disjointness assertion
# Union of everything machorun's userland exports. Note this reads the BUILT
# dylibs, not the .tbds: a .tbd is generated from a dylib and can lag it, and
# what decides a flat bind at runtime is the dylib.
#
# IT DISCOVERS THE DYLIBS RATHER THAN LISTING THEM, and that is deliberate. This
# loop was once four hardcoded names with `[ -f ] || continue`, which has two
# failure modes that both report success: a library that is MISSING is skipped
# silently (grade three of four, print "disjoint"), and a library that is NEW is
# never looked at (machorun's own CHECK 4 was scoped to the list someone
# happened to have, which is exactly how the libc++abi overlap went unseen).
# Discovery fixes the second; the refusals below fix the first.
#
# libswiftcompat itself is excluded -- it is the thing being graded, and a
# previously staged copy of it would collide with the new build on every symbol.
: > "$tmp/userland.txt"; : > "$tmp/examined.txt"
while IFS= read -r f; do
  case "$(basename "$f")" in libswiftcompat.dylib) continue ;; esac
  # `|| true` is load-bearing, not laziness. Under `set -o pipefail` a truncated
  # or malformed dylib makes nm exit nonzero, which killed this script HERE --
  # silently, with exit 1, before REFUSAL 3 below could ever report it. A guard
  # written for exactly the truncated-file hazard could not fire. Absorb the
  # failure so the empty read becomes a COUNT, which the refusals can grade.
  "$NM" --defined-only --extern-only "$f" 2>/dev/null | awk '{print $NF}' \
        > "$tmp/one.txt" || true
  n=$(wc -l < "$tmp/one.txt" | tr -d ' ')
  cat "$tmp/one.txt" >> "$tmp/userland.raw"
  # Full path as well as basename: libswiftCore.dylib lives in a subdirectory,
  # so re-deriving "$MRLIB/$basename" later would silently fail to find it.
  printf '%s\t%s\t%s\n' "$(basename "$f")" "$n" "$f" >> "$tmp/examined.txt"
done < <(find "$MRLIB" -type f -name '*.dylib' ! -name '.*' 2>/dev/null | sort)
# `! -name '.*'`: scripts/env/prepare.py (PR #65) writes a product stamp
# `.source-tree.<basename>` beside each artefact; `.source-tree.libSystem.B.dylib`
# matched the glob, read as 0 symbols, and the zero-symbol refusal below fired
# (measured 2026-09-03 on the x86_64 box, main 0c2cbf39).
sort -u "$tmp/userland.raw" 2>/dev/null > "$tmp/userland.txt" || true

# Fold the LOADER's exports into the userland set. In machorun the loader IS
# dyld, so the whole dyld surface lives in build/machorun and in no dylib at
# all; a shim symbol colliding with one of those is the same defect as one
# colliding with libSystem's. `nm -g` on an ELF file, not the Mach-O reader
# above -- different format, different tool, which is why it is a separate step.
loadn=0
if [ -f "$LOADER" ]; then
  nm -g "$LOADER" 2>/dev/null | awk '$2 ~ /^[TDBRW]$/ {print "_"$3}' | sort -u > "$tmp/loader.txt" || : > "$tmp/loader.txt"
  loadn=$(wc -l < "$tmp/loader.txt" | tr -d ' ')
fi
if [ "${loadn:-0}" -gt 0 ]; then
  printf '%s\t%s\t%s\n' "machorun(loader)" "$loadn" "$LOADER" >> "$tmp/examined.txt"
  sort -u "$tmp/userland.txt" "$tmp/loader.txt" > "$tmp/u2.txt" && mv "$tmp/u2.txt" "$tmp/userland.txt"
else
  echo "note: no loader symbols read from $LOADER -- the dyld surface is NOT in this comparison" >&2
fi

examined=$(wc -l < "$tmp/examined.txt" | tr -d ' ')

# REFUSAL 1: nothing to grade against. A vacuous pass is worse than no check.
if [ "$examined" -eq 0 ] || [ ! -s "$tmp/userland.txt" ]; then
  echo "REFUSING TO GRADE: found $examined dylib(s) under $MRLIB." >&2
  echo "The overlap check would pass vacuously, which is worse than not running it." >&2
  exit 2
fi

# REFUSAL 2: the denominator. A sweep that reports "clean" without reporting how
# many things it compared is indistinguishable from one that compared none, so
# the libraries whose absence would make this check meaningless are named, and
# their absence is a refusal rather than a smaller number nobody notices.
missing=""
for want in libSystem.B.dylib libc++abi.dylib; do
  grep -q "^$want	" "$tmp/examined.txt" || missing="$missing $want"
done
if [ -n "$missing" ]; then
  echo "REFUSING TO GRADE: examined $examined dylib(s), but these were absent:$missing" >&2
  echo "  found: $(cut -f1 "$tmp/examined.txt" | tr '\n' ' ')" >&2
  echo "  They own the symbols this shim is most likely to collide with, so a" >&2
  echo "  'disjoint' verdict without them means nothing. Check MRLIB=$MRLIB." >&2
  exit 2
fi

# A library that reads as zero symbols is a broken read, not an empty library.
while IFS=$'\t' read -r name count path; do
  [ "$count" -gt 0 ] || {
    echo "REFUSING TO GRADE: $name listed 0 external symbols." >&2
    echo "  That is a failed read, not an empty library, and it silently shrinks" >&2
    echo "  the set this shim is compared against." >&2
    exit 2
  }
done < "$tmp/examined.txt"

overlap=$(comm -12 "$tmp/shim_exports.txt" "$tmp/userland.txt")
if [ -n "$overlap" ]; then
  echo >&2
  echo "BUILD REFUSED: libswiftcompat defines $(printf '%s\n' "$overlap" | wc -l) symbol(s) machorun's userland already defines." >&2
  echo >&2
  printf '%s\n' "$overlap" | while read -r s; do
    # The loader row is an ELF file; the Mach-O reader returns nothing for it,
    # which produced a refusal that named no owner at all. Read it with the
    # already-extracted list instead of re-running the wrong tool on it.
    where=$(while IFS=$'\t' read -r lib _ path; do
              case "$lib" in
                "machorun(loader)") grep -qx "$s" "$tmp/loader.txt" 2>/dev/null && echo "$lib" ;;
                *) "$NM" --defined-only --extern-only "$path" 2>/dev/null \
                     | awk -v s="$s" -v l="$lib" '$NF==s {print l}' ;;
              esac
            done < "$tmp/examined.txt" | tr '\n' ' ')
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
echo "exports: $(wc -l < "$tmp/shim_exports.txt" | tr -d ' ')  -- disjoint from machorun's userland"
# The denominator, always. A "disjoint" verdict is only as good as the set it
# was compared against, so the set is printed rather than implied.
echo "graded against $examined dylib(s), $(wc -l < "$tmp/userland.txt" | tr -d ' ') distinct symbols:"
while IFS=$'\t' read -r lib count _; do printf '   %-24s %6s symbols\n' "$lib" "$count"; done < "$tmp/examined.txt"
