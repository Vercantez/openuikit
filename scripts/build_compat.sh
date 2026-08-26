#!/bin/bash
# Build libswiftcompat.dylib — the 29-symbol gap between our libswiftCore.dylib
# and machorun's self-hosted Darwin userland. See sdk/compat/swiftcompat.c.
set -euo pipefail
W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
TC=${TC:-/opt/swift624/usr}
OUT=${OUT:-$W/machorun/darwin/usr/lib/libswiftcompat.dylib}
mkdir -p "$(dirname "$OUT")"

"$TC/bin/clang" -target arm64-apple-macos13.0 -isysroot "$SDK" -O1 -fPIC \
  -Wno-incompatible-library-redeclaration -Wno-builtin-requires-header \
  -c "$W/compat/swiftcompat.c" -o /tmp/swiftcompat.o

"$TC/bin/clang++" -target arm64-apple-macos13.0 -isysroot "$SDK" -O1 -fPIC -std=c++17 -fno-exceptions -fno-rtti \
  -c "$W/compat/shim.cpp" -o /tmp/shim.o

"$TC/bin/clang++" -target arm64-apple-macos13.0 -isysroot "$SDK" \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" \
  -dynamiclib -install_name /usr/lib/libswiftcompat.dylib \
  -compatibility_version 1 -current_version 1 \
  -nostdlib -L"$SDK/usr/lib" \
  /tmp/swiftcompat.o /tmp/shim.o \
  -lSystem -lc++ \
  -Wl,-undefined,dynamic_lookup \
  -o "$OUT"

echo "built: $OUT"
/usr/lib/llvm-18/bin/llvm-nm --defined-only --extern-only "$OUT" | awk '{print $NF}' | sort > /tmp/compat_exports.txt
echo "exports: $(wc -l < /tmp/compat_exports.txt)"
echo "--- still missing after this shim ---"
comm -23 /tmp/missing30.txt /tmp/compat_exports.txt || true
