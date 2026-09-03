#!/usr/bin/env bash
# Build a Darwin-target compiler-rt builtins archive with os_version_check.c
# (Apple's libclang_rt.osx.a piece that defines __isPlatformVersionAtLeast).
#
# Usage: build_compiler_rt_osx.sh [output.a]
# Env: SWIFTCORE_SDKROOT or SWIFTCORE_DARWIN_SDK, SWIFTCORE_DARWIN_ARCH,
#      DARWIN_MIN, clang on PATH (or CC / DARWIN_CLANG).
set -euo pipefail
_here=$(cd "$(dirname "$0")" && pwd)
_root=$(cd "$_here/../.." && pwd)
: "${SWIFTCORE_DARWIN_ARCH:=x86_64}"
: "${DARWIN_MIN:=macosx13.0}"
min_ver="${DARWIN_MIN#macosx}"
sdk="${SWIFTCORE_SDKROOT:-${SWIFTCORE_DARWIN_SDK:-${SWIFTCORE_WORK:-$HOME/work}/sdk/MacOSX.sdk}}"
out="${1:-${SWIFTCORE_COMPILER_RT_OSX:-${SWIFTCORE_WORK:-$HOME/work}/build/libclang_rt.osx.a}}"
src_dir="$_root/swiftcore-macho/compiler-rt"
if [[ -n "${DARWIN_CLANG:-}" ]]; then
  cc="$DARWIN_CLANG"
elif [[ -n "${CC:-}" ]]; then
  cc="$CC"
elif command -v clang-18 >/dev/null 2>&1; then
  cc=clang-18
else
  cc=clang
fi

if [[ ! -d "$sdk" ]]; then
  echo "build_compiler_rt_osx.sh: no SDK at $sdk" >&2
  exit 1
fi
if [[ ! -f "$src_dir/os_version_check.c" ]]; then
  echo "build_compiler_rt_osx.sh: missing $src_dir/os_version_check.c" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
target="${SWIFTCORE_DARWIN_ARCH}-apple-macos${min_ver}"

cflags=(
  -target "$target"
  -isysroot "$sdk"
  -std=c11
  -fPIC
  -O2
  -fno-stack-protector
  -fvisibility=hidden
  -Wno-deprecated-declarations
)

"$cc" "${cflags[@]}" -c "$src_dir/os_version_check.c" \
  -o "$tmpdir/os_version_check.o"

mkdir -p "$(dirname "$out")"
rm -f "$out"
ar rcs "$out" "$tmpdir/os_version_check.o"
# Confirm the Darwin availability hooks landed; llvm-nm understands Mach-O.
nm_bin=""
for cand in /usr/lib/llvm-18/bin/llvm-nm llvm-nm nm; do
  if command -v "$cand" >/dev/null 2>&1 || [[ -x "$cand" ]]; then
    nm_bin=$cand
    break
  fi
done
if [[ -n "$nm_bin" ]]; then
  "$nm_bin" "$out" 2>/dev/null | grep -E 'isPlatformVersionAtLeast|isPlatformOrVariantPlatformVersionAtLeast|_availability_version_check' \
    | sed 's/^/  compiler-rt nm: /' || true
fi
echo "compiler-rt darwin builtins: $out"
