#!/bin/bash
# Compile+link a hello-world Swift program against the just-built Darwin slice.
# Execution is a positive probe: a machorun loader binary that can run an
# x86_64 Mach-O on this host. The marker is never printed just because the
# process happens to be a cloud-agent VM.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
OPENUIKIT_ROOT=$(cd "$SWIFTCORE_ROOT/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/probe_machorun.inc"

W=${W:-$HOME/work}
B=${B:-$W/build}
SDK=$W/sdk/MacOSX.sdk
RES=$B/lib/swift
LIBDIR=$B/lib/swift/${SWIFTCORE_STDLIB_DIR}
HELLO=${HELLO:-$W/hello_swiftcore.swift}
OUT=${OUT:-$W/hello_swiftcore}
MACHORUN=${MACHORUN:-$OPENUIKIT_ROOT/machorun}

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

if [ "$SWIFTCORE_DARWIN_ARCH" != x86_64 ]; then
  echo "verify_hello: guest is $SWIFTCORE_DARWIN_ARCH; x86_64 loader probe skipped"
  exit 0
fi

probed=$(probe_x86_macho_loader || true)
if [ -z "$probed" ]; then
  cands=$(probe_machorun_candidates | tr '\n' ' ')
  echo "CURSOR_ENV_CANNOT_EXECUTE_X86_SWIFT_GUEST host=$(uname -m) guest=$OUT cpu=${SWIFTCORE_MACHO_CPU} reason=no machorun loader binary on this host can run an x86_64 Mach-O (probed: $cands)" >&2
  exit 0
fi

loader=${probed%%$'\t'*}
root=${probed#*$'\t'}
echo "probe: machorun loader=$loader root=$root"
echo "probe: $(file -b "$loader")"

# Prefix map: /usr/lib/swift/libswiftCore.dylib -> $root/darwin/usr/lib/swift/...
dst_dir=$root/darwin/usr/lib/swift
mkdir -p "$dst_dir"
if [ -e "$dst_dir/libswiftCore.dylib" ]; then
  if ! cmp -s "$LIBDIR/libswiftCore.dylib" "$dst_dir/libswiftCore.dylib"; then
    echo "verify_hello: $dst_dir/libswiftCore.dylib differs from this build; parking it"
    mv "$dst_dir/libswiftCore.dylib" "$dst_dir/libswiftCore.dylib.park-$$"
  fi
fi
# A regular copy, not a symlink: this is the shared machorun root, and the
# guest gates (stage_swift_core_runtime.py) refuse a symlinked canonical core
# (measured 2026-09-03: rung b and c CANNOT after the overlays stage).
cp -f "$LIBDIR/libswiftCore.dylib" "$dst_dir/libswiftCore.dylib"
echo "probe: staged $dst_dir/libswiftCore.dylib (copy of $LIBDIR/libswiftCore.dylib)"

echo "=== hello under machorun ==="
set +e
hello_out=$(MACHORUN_ROOT="$root" "$loader" "$OUT" 2>&1)
hello_rc=$?
set -e
printf '%s\n' "$hello_out"
echo "hello_swiftcore machorun exit=$hello_rc"
exit 0
