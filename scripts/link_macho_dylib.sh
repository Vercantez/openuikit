#!/bin/bash
# Link a Darwin Mach-O dylib from the objects a ninja build produced.
#
#   link_macho_dylib.sh <ninja-log> <libname> [extra ld flags...]
#
# e.g. link_macho_dylib.sh ~/work/build.log libswiftCore
#      link_macho_dylib.sh ~/work/build.log libswift_Concurrency
#
# WHY THIS EXISTS: every object compiles, but CMake generates the *link* command
# from its host platform (Linux), emitting `-shared -soname libX.so -fuse-ld=gold`
# even though every surrounding flag is Darwin (-sectcreate __TEXT,__info_plist,
# -application_extension, -compatibility_version). CMAKE_SHARED_LIBRARY_SUFFIX and
# the SONAME flag come from Modules/Platform/Linux.cmake and no Swift-level
# variable overrides them. So we perform the link the way a Darwin host would,
# from exactly the object list ninja assembled — not a re-glob, so it stays what
# the build system intended.
set -euo pipefail
LOG=${1:?usage: link_macho_dylib.sh <ninja-log> <libname> [extra flags]}
LIB=${2:?missing libname (e.g. libswiftCore)}
shift 2
W=${W:-$HOME/work}
B=${B:-$W/build}
SDK=$W/sdk/MacOSX.sdk
TC=${TC:-/opt/swift624/usr}
OUT=${OUT:-$B/lib/swift/macosx/arm64/$LIB.dylib}

OBJS=$(LOG="$LOG" LIB="$LIB" python3 - <<'PY'
import os, pathlib, sys
log = pathlib.Path(os.environ["LOG"]); lib = os.environ["LIB"]
needle = f"-o lib/swift/macosx/arm64/{lib}.so"
line = next((l for l in log.read_text(errors="replace").splitlines() if needle in l), None)
if line is None:
    sys.exit(f"no link line for {lib} in {log}")
toks = line.split()
i = toks.index("-o")
print(" ".join(t for t in toks[i+2:] if t.endswith((".o", ".obj"))))
PY
)
test -n "$OBJS"
echo "$LIB: $(echo $OBJS | wc -w) objects"

mkdir -p "$(dirname "$OUT")"
cd "$B"
"$TC/bin/clang++" \
  -target arm64-apple-macosx13.0 -isysroot "$SDK" \
  `# the swift toolchain's own lld refuses platform macOS; Ubuntu's ld64.lld-18 does not` \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" \
  -dynamiclib -install_name "/usr/lib/swift/$LIB.dylib" \
  -compatibility_version 1 -current_version 1 \
  -Wl,-application_extension \
  -L"$SDK/usr/lib" -L"$B/lib/swift/macosx/arm64" \
  -nostdlib $OBJS \
  -lSystem -lobjc -lc++ \
  -Wl,-undefined,dynamic_lookup \
  -o "$OUT" "$@"

echo "linked: $OUT"
/usr/lib/llvm-18/bin/llvm-otool -h "$OUT" 2>/dev/null | tail -2
