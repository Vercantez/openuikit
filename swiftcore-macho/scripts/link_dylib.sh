#!/bin/bash
# Link libswiftCore.dylib from the objects the ninja build produced.
#
# Why this exists: every object file compiles, but CMake generates the *link*
# command from its host platform (Linux), so it emits `-shared -soname
# libswiftCore.so -fuse-ld=gold` even though every flag around it is Darwin
# (-sectcreate __TEXT,__info_plist, -application_extension,
# -compatibility_version). CMAKE_SHARED_LIBRARY_SUFFIX and the SONAME flag come
# from Modules/Platform/Linux.cmake and no Swift-level variable overrides them.
# This script performs the link the way a Darwin host would, from exactly the
# object list ninja assembled, so the artifact does not wait on that fix.
set -euo pipefail
W=${W:-$HOME/work}
B=$W/build
SDK=$W/sdk/MacOSX.sdk
TC=${TC:-/opt/swift624/usr}
OUT=${OUT:-$B/lib/swift/macosx/arm64/libswiftCore.dylib}

# The object list, taken from the failing link edge rather than re-globbed, so
# it stays exactly what the build system intended to link.
cd "$B"
OBJS=$(python3 - <<'PY'
import re, pathlib
log = pathlib.Path.home()/ "work" / "build4.log"
line = next(l for l in log.read_text().splitlines()
            if "-o lib/swift/macosx/arm64/libswiftCore.so" in l)
toks = line.split()
i = toks.index("-o")
objs = [t for t in toks[i+2:] if t.endswith((".o", ".obj"))]
print(" ".join(objs))
PY
)
test -n "$OBJS"
echo "objects: $(echo $OBJS | wc -w)"

mkdir -p "$(dirname "$OUT")"
"$TC/bin/clang++" \
  -target arm64-apple-macosx13.0 \
  -isysroot "$SDK" \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" \
  -dynamiclib \
  -install_name /usr/lib/swift/libswiftCore.dylib \
  -compatibility_version 1 -current_version 1 \
  -Wl,-application_extension \
  -Wl,-sectcreate,__TEXT,__info_plist,"$B/stdlib/public/core/Info.plist" \
  -L"$SDK/usr/lib" \
  -nostdlib \
  $OBJS \
  -lSystem -lobjc -lc++ \
  -o "$OUT" \
  "$@"

echo "linked: $OUT"
ls -la "$OUT"
