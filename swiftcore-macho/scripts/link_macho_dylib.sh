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
cd "$B"
"$TC/bin/clang++" \
  -target "$SWIFTCORE_CLANG_TARGET" -isysroot "$SDK" \
  `# the swift toolchain's own lld refuses platform macOS; Ubuntu's ld64.lld-18 does not` \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" \
  -dynamiclib -install_name "/usr/lib/swift/$LIB.dylib" \
  -compatibility_version 1 -current_version 1 \
  -Wl,-application_extension \
  -L"$SDK/usr/lib" -L"$B/lib/swift/${SWIFTCORE_STDLIB_DIR}" \
  -nostdlib $OBJS \
  -lSystem -lobjc -lc++ \
  -Wl,-undefined,dynamic_lookup \
  -o "$OUT" "$@"

echo "linked: $OUT"
if [ "$OUT_SO" != "$OUT" ]; then
  cp -f "$OUT" "$OUT_SO"
  echo "linked: $OUT_SO (ninja .so name)"
fi
/usr/lib/llvm-18/bin/llvm-otool -hv "$OUT" 2>/dev/null | tail -3
