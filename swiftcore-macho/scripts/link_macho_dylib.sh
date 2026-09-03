#!/bin/bash
# Link a Darwin Mach-O dylib from the objects a ninja build produced.
#
#   link_macho_dylib.sh <ninja-log> <libname> [extra ld flags...]
#
# e.g. link_macho_dylib.sh ~/work/build.log libswiftCore
#      link_macho_dylib.sh ~/work/build.log libswift_Concurrency
#
# WHY THIS EXISTS: every object compiles, but CMake generates the *link*
# command from its host platform (Linux), emitting `-shared -soname
# libX.so -fuse-ld=gold` even though every surrounding flag is Darwin.
# CMAKE_SHARED_LIBRARY_SUFFIX and the SONAME flag come from
# Modules/Platform/Linux.cmake. So we perform the link the way a Darwin host
# would, from exactly the object list ninja assembled — not a re-glob.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

LOG=${1:?usage: link_macho_dylib.sh <ninja-log> <libname> [extra flags]}
LIB=${2:?missing libname (e.g. libswiftCore)}
shift 2
W=${W:-$HOME/work}
B=${B:-$W/build}
SDK=$W/sdk/MacOSX.sdk
OUT=${OUT:-$B/lib/swift/${SWIFTCORE_STDLIB_DIR}/$LIB.dylib}
# Ninja's Linux CMake graph names the same file .so. Stage both so overlay
# targets that depend on lib/swift/macosx/<arch>/$LIB.so can proceed.
OUT_SO=${OUT_SO:-$B/lib/swift/${SWIFTCORE_STDLIB_DIR}/$LIB.so}

NEEDLE_ARCH=${SWIFTCORE_DARWIN_ARCH}
OBJS=$(LOG="$LOG" LIB="$LIB" NEEDLE_ARCH="$NEEDLE_ARCH" python3 - <<'PY'
import os, pathlib, sys
log = pathlib.Path(os.environ["LOG"]); lib = os.environ["LIB"]
arch = os.environ["NEEDLE_ARCH"]
needle = f"-o lib/swift/macosx/{arch}/{lib}.so"
line = next((l for l in log.read_text(errors="replace").splitlines() if needle in l), None)
if line is None:
    sys.exit(f"no link line for {lib} (needle {needle}) in {log}")
toks = line.split()
i = toks.index("-o")
print(" ".join(t for t in toks[i+2:] if t.endswith((".o", ".obj"))))
PY
)
test -n "$OBJS"
echo "$LIB: $(echo $OBJS | wc -w) objects  arch=${SWIFTCORE_DARWIN_ARCH}"

mkdir -p "$(dirname "$OUT")"
# libswiftDarwin: Apple's dylib carries exactly four LC_REEXPORT_DYLIB
# (Builtin_float, _DarwinFoundation1/2/3). This object-list relink runs AFTER
# the ninja link + overlay_ensure_darwin_reexports and used to overwrite that
# image without them (measured 2026-09-03: staged Darwin had no re-exports).
# Link at macosx15.0: our Builtin_float carries
# `$ld$previous$/usr/lib/swift/libswiftDarwin.dylib$$1$10.14.4$15.0$$`, and at
# the 13.0 CMake target lld records that re-export under the previous name.
LINK_TARGET=$SWIFTCORE_CLANG_TARGET
REEXPORT_FLAGS=()
if [ "$LIB" = libswiftDarwin ]; then
  for shell in libswift_Builtin_float libswift_DarwinFoundation1 \
               libswift_DarwinFoundation2 libswift_DarwinFoundation3; do
    sp=$B/lib/swift/${SWIFTCORE_STDLIB_DIR}/$shell.dylib
    [ -f "$sp" ] || { echo "link_macho_dylib: CANNOT_DARWIN_REEXPORT missing $sp" >&2; exit 2; }
    REEXPORT_FLAGS+=(-Wl,-reexport_library,"$sp")
  done
  LINK_TARGET=$(printf '%s' "$SWIFTCORE_CLANG_TARGET" | sed -E 's/-macosx[0-9.]+$/-macosx15.0/')
  echo "link_macho_dylib: libswiftDarwin target=$LINK_TARGET reexport=4 shells"
fi
cd "$B"
"$TC/bin/clang++" \
  -target "$LINK_TARGET" -isysroot "$SDK" \
  `# the swift toolchain's own lld refuses platform macOS; Ubuntu's ld64.lld-18 does not` \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" \
  -dynamiclib -install_name "/usr/lib/swift/$LIB.dylib" \
  -compatibility_version 1 -current_version 1 \
  -Wl,-application_extension \
  -L"$SDK/usr/lib" -L"$B/lib/swift/${SWIFTCORE_STDLIB_DIR}" \
  -nostdlib $OBJS \
  -lSystem -lobjc -lc++ \
  -Wl,-undefined,dynamic_lookup \
  "${REEXPORT_FLAGS[@]}" \
  -o "$OUT" "$@"

echo "linked: $OUT"
if [ "$LIB" = libswiftDarwin ]; then
  have=$(/usr/lib/llvm-18/bin/llvm-otool -l "$OUT" 2>/dev/null \
    | awk '/LC_REEXPORT_DYLIB/{r=1} r&&/^ *name /{print $2; r=0}' | sort -u | paste -sd, -)
  want=/usr/lib/swift/libswift_Builtin_float.dylib,/usr/lib/swift/libswift_DarwinFoundation1.dylib,/usr/lib/swift/libswift_DarwinFoundation2.dylib,/usr/lib/swift/libswift_DarwinFoundation3.dylib
  [ "$have" = "$want" ] || { echo "link_macho_dylib: CANNOT_DARWIN_REEXPORT have=[$have]" >&2; exit 2; }
  echo "link_macho_dylib: libswiftDarwin LC_REEXPORT_DYLIB = Apple's four"
fi
if [ "$OUT_SO" != "$OUT" ]; then
  cp -f "$OUT" "$OUT_SO"
  echo "linked: $OUT_SO (ninja .so name)"
fi
/usr/lib/llvm-18/bin/llvm-otool -hv "$OUT" 2>/dev/null | tail -3
