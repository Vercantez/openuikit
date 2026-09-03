#!/bin/bash
# Compile+link a hello-world Swift program against the just-built Darwin slice.
# Execution is refused: this cloud-agent VM is not the operator x86 host.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

W=${W:-$HOME/work}
B=${B:-$W/build}
SDK=$W/sdk/MacOSX.sdk
RES=$B/lib/swift
LIBDIR=$B/lib/swift/${SWIFTCORE_STDLIB_DIR}
HELLO=${HELLO:-$W/hello_swiftcore.swift}
OUT=${OUT:-$W/hello_swiftcore}

if [ ! -f "$LIBDIR/libswiftCore.dylib" ]; then
  echo "verify_hello: no $LIBDIR/libswiftCore.dylib" >&2
  exit 2
fi

cat > "$HELLO" <<'EOF'
print("hello from Swift on machorun")
print("sorted: \([3, 1, 2].sorted())")
EOF

# Disable implicit overlay imports when those modules were not built this run.
IMPLICIT=()
if [ ! -d "$RES/macosx/_Concurrency.swiftmodule" ]; then
  IMPLICIT+=(-disable-implicit-concurrency-module-import)
fi
if [ ! -d "$RES/macosx/_StringProcessing.swiftmodule" ]; then
  IMPLICIT+=(-disable-implicit-string-processing-module-import)
fi

"${TC}/bin/swiftc" -c \
  -target "$SWIFTCORE_SWIFTC_TARGET" \
  -sdk "$SDK" \
  -resource-dir "$RES" \
  -O \
  "${IMPLICIT[@]}" \
  "$HELLO" -o "${OUT}.o"

"${TC}/bin/clang" \
  -target "$SWIFTCORE_CLANG_TARGET" \
  -isysroot "$SDK" \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" \
  -nostdlib \
  -L"$SDK/usr/lib" -L"$LIBDIR" \
  "${OUT}.o" \
  -lswiftCore -lSystem -lobjc \
  -o "$OUT"

echo "=== hello Mach-O ==="
file "$OUT"
llvm-otool-18 -hv "$OUT" | tail -4
llvm-otool-18 -L "$OUT" | head -10

hdr=$(llvm-otool-18 -hv "$OUT")
echo "$hdr" | grep -Eq "MH_MAGIC_64[[:space:]]+${SWIFTCORE_MACHO_CPU}" \
  || { echo "verify_hello: guest is not ${SWIFTCORE_MACHO_CPU}" >&2; exit 1; }
if [ "$SWIFTCORE_DARWIN_ARCH" = x86_64 ]; then
  if echo "$hdr" | grep -q ARM64; then
    echo "verify_hello: ARM64 token sneaked into the x86_64 guest" >&2
    exit 1
  fi
fi

echo "compile+link OK  guest=$OUT  cpu=$SWIFTCORE_MACHO_CPU"
echo "CURSOR_ENV_CANNOT_EXECUTE_X86_SWIFT_GUEST host=$(uname -m) split=compile-link-in-vm/execution-operator-x86-ec2 reason=linked Mach-O $OUT is ${SWIFTCORE_MACHO_CPU}; running it needs the ported machorun loader on the operator x86 host, not this cloud-agent VM" >&2
exit 0
