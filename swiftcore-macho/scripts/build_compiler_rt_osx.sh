#!/usr/bin/env bash
# Compile compiler-rt os_version_check.c as a Darwin-target static object
# (Apple ships this TU in libclang_rt.osx.a). Linked into every Darwin overlay
# as an object, not a dylib export.
#
# Usage: build_compiler_rt_osx.sh [output.o]
# Env: SWIFTCORE_SDKROOT or SWIFTCORE_DARWIN_SDK, SWIFTCORE_DARWIN_ARCH,
#      DARWIN_MIN, clang on PATH (or CC / DARWIN_CLANG).
#
# Arch-parametric: default output is
#   $W/build/compiler-rt/os_version_check.${SWIFTCORE_DARWIN_ARCH}.o
# Fails loudly if the sysroot lacks <dispatch/dispatch.h>, <dlfcn.h>, or
# CoreFoundation headers the TU wants.
set -euo pipefail
_here=$(cd "$(dirname "$0")" && pwd)
_root=$(cd "$_here/../.." && pwd)
# Do not source guest_arch.inc: that script requires swiftc. Arch is env-only.
: "${SWIFTCORE_DARWIN_ARCH:=x86_64}"
: "${DARWIN_MIN:=macosx13.0}"
min_ver="${DARWIN_MIN#macosx}"
sdk="${SWIFTCORE_SDKROOT:-${SWIFTCORE_DARWIN_SDK:-${SWIFTCORE_WORK:-$HOME/work}/sdk/MacOSX.sdk}}"
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

need_header() {
  local rel=$1
  local p
  for p in \
    "$sdk/usr/include/$rel" \
    "$sdk/System/Library/Frameworks/CoreFoundation.framework/Headers/${rel#CoreFoundation/}"
  do
    if [[ -f "$p" ]]; then
      echo "build_compiler_rt_osx.sh: header <$rel> -> $p"
      return 0
    fi
  done
  echo "build_compiler_rt_osx.sh: sysroot $sdk lacks <$rel>" >&2
  echo "build_compiler_rt_osx.sh: os_version_check.c wants dispatch, dlfcn, CoreFoundation" >&2
  exit 1
}
need_header "dispatch/dispatch.h"
need_header "dlfcn.h"
need_header "CoreFoundation/CoreFoundation.h"

work="${SWIFTCORE_WORK:-${W:-$HOME/work}}"
bdir="${B:-$work/build}"
out="${1:-${SWIFTCORE_COMPILER_RT_OSX:-$bdir/compiler-rt/os_version_check.${SWIFTCORE_DARWIN_ARCH}.o}}"
# Same Darwin driver argv the overlays use: -target <arch>-apple-macos, -isysroot.
target="${SWIFTCORE_DARWIN_ARCH}-apple-macos${min_ver}"

cflags=(
  -target "$target"
  -isysroot "$sdk"
  -std=c11
  -fPIC
  -O2
  -fno-stack-protector
  -Wno-deprecated-declarations
  -Wno-macro-redefined
)

mkdir -p "$(dirname "$out")"
echo "build_compiler_rt_osx.sh: $cc ${cflags[*]} -c $src_dir/os_version_check.c -o $out"
"$cc" "${cflags[@]}" -c "$src_dir/os_version_check.c" -o "$out"

nm_bin=""
for cand in /usr/lib/llvm-18/bin/llvm-nm llvm-nm-18 llvm-nm; do
  if command -v "$cand" >/dev/null 2>&1 || [[ -x "$cand" ]]; then
    nm_bin=$cand
    break
  fi
done
if [[ -z "$nm_bin" ]]; then
  echo "build_compiler_rt_osx.sh: need llvm-nm to confirm the availability object" >&2
  exit 1
fi
if ! "$nm_bin" "$out" 2>/dev/null | grep -q 'isPlatformVersionAtLeast'; then
  echo "build_compiler_rt_osx.sh: $out missing isPlatformVersionAtLeast" >&2
  "$nm_bin" "$out" >&2 || true
  exit 1
fi
"$nm_bin" "$out" 2>/dev/null | grep -E 'isPlatformVersionAtLeast|isPlatformOrVariantPlatformVersionAtLeast' \
  | sed 's/^/  compiler-rt nm: /' || true
echo "compiler-rt darwin availability object: $out"
