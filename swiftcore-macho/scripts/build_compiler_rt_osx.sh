#!/usr/bin/env bash
# Build Apple's-shape Darwin compiler-rt builtins archive (libclang_rt.osx.a).
#
# Generic C builtins + the x86_64 (or arm64) .c/.S files Apple includes for
# that arch, from a pinned llvm-project compiler-rt (llvmorg-18.1.8). One
# file per missing symbol is the wrong shape: ld64 archive-searches the
# whole library (__divti3, __udivti3, __floattidf, atomics, …).
#
# os_version_check.c is the in-tree override (always-yes
# _availability_version_check, local dispatch_once_f) — not upstream.
#
# Usage: build_compiler_rt_osx.sh [output.a]
# Env: SWIFTCORE_SDKROOT or SWIFTCORE_DARWIN_SDK, SWIFTCORE_DARWIN_ARCH,
#      DARWIN_MIN, clang on PATH (or CC / DARWIN_CLANG).
set -euo pipefail
_here=$(cd "$(dirname "$0")" && pwd)
_root=$(cd "$_here/../.." && pwd)
# Pins duplicated from guest_arch.inc so this script does not require swiftc.
LLVM_PROJECT_PIN_TAG=llvmorg-18.1.8
LLVM_PROJECT_PIN_COMMIT=3b5b5c1ec4a3095ab096dd780e84d7ab81f3d7ff
COMPILER_RT_SRC_TAR_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/compiler-rt-18.1.8.src.tar.xz
COMPILER_RT_SRC_TAR_SHA256=e054e99a9c9240720616e927cb52363abbc8b4f1ef0286bad3df79ec8fdf892f
: "${SWIFTCORE_DARWIN_ARCH:=x86_64}"
: "${DARWIN_MIN:=macosx13.0}"
min_ver="${DARWIN_MIN#macosx}"
sdk="${SWIFTCORE_SDKROOT:-${SWIFTCORE_DARWIN_SDK:-${SWIFTCORE_WORK:-$HOME/work}/sdk/MacOSX.sdk}}"
out="${1:-${SWIFTCORE_COMPILER_RT_OSX:-${SWIFTCORE_WORK:-$HOME/work}/build/libclang_rt.osx.a}}"
override="$_root/swiftcore-macho/compiler-rt/os_version_check.c"
W=${SWIFTCORE_WORK:-${W:-$HOME/work}}

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
if [[ ! -f "$override" ]]; then
  echo "build_compiler_rt_osx.sh: missing $override" >&2
  exit 1
fi

# --- fetch pinned compiler-rt into scratch/ (do not commit sources) ---
_fetch_compiler_rt() {
  local scratch tar dest got
  scratch="${SWIFTCORE_LLVM_SRC:-}"
  if [[ -z "$scratch" ]]; then
    for d in \
      "$W/scratch/llvm-project/compiler-rt/lib/builtins" \
      "$_root/scratch/llvm-project/compiler-rt/lib/builtins" \
      "$W/scratch/compiler-rt-18.1.8.src/lib/builtins" \
      "$_root/scratch/compiler-rt-18.1.8.src/lib/builtins"
    do
      if [[ -f "$d/divti3.c" && -f "$d/CMakeLists.txt" ]]; then
        printf '%s\n' "$d"
        return 0
      fi
    done
    scratch="$W/scratch"
  fi
  mkdir -p "$scratch"
  dest="$scratch/compiler-rt-18.1.8.src"
  if [[ -f "$dest/lib/builtins/divti3.c" ]]; then
    printf '%s\n' "$dest/lib/builtins"
    return 0
  fi
  tar="$scratch/compiler-rt-18.1.8.src.tar.xz"
  if [[ ! -f "$tar" ]]; then
    echo "build_compiler_rt_osx.sh: fetching $COMPILER_RT_SRC_TAR_URL" >&2
    curl -fsSL -o "$tar" "$COMPILER_RT_SRC_TAR_URL"
  fi
  got=$(sha256sum "$tar" | awk '{print $1}')
  if [[ "$got" != "$COMPILER_RT_SRC_TAR_SHA256" ]]; then
    echo "build_compiler_rt_osx.sh: tarball sha256 $got != pin $COMPILER_RT_SRC_TAR_SHA256" >&2
    exit 2
  fi
  tar -xJf "$tar" -C "$scratch"
  if [[ ! -f "$dest/lib/builtins/divti3.c" ]]; then
    echo "build_compiler_rt_osx.sh: extract missing lib/builtins/divti3.c" >&2
    exit 2
  fi
  echo "build_compiler_rt_osx.sh: compiler-rt $LLVM_PROJECT_PIN_TAG commit=$LLVM_PROJECT_PIN_COMMIT tar_sha256=$COMPILER_RT_SRC_TAR_SHA256" >&2
  printf '%s\n' "$dest/lib/builtins"
}

builtins=$(_fetch_compiler_rt)

ar_bin=""
for cand in /usr/lib/llvm-18/bin/llvm-ar llvm-ar-18 llvm-ar; do
  if [[ -x "$cand" ]] || command -v "$cand" >/dev/null 2>&1; then
    ar_bin=$cand
    break
  fi
done
if [[ -z "$ar_bin" ]]; then
  echo "build_compiler_rt_osx.sh: need llvm-ar (GNU ar has no Darwin index)" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
objdir="$tmpdir/obj"
mkdir -p "$objdir"
target="${SWIFTCORE_DARWIN_ARCH}-apple-macos${min_ver}"

cflags=(
  -target "$target"
  -isysroot "$sdk"
  -std=c11
  -fPIC
  -fno-builtin
  -O2
  -fno-stack-protector
  -fvisibility=hidden
  -Wno-deprecated-declarations
  -Wno-unused-parameter
  -Wno-atomic-alignment
  -I "$builtins"
  -I "$builtins/cpu_model"
)

asflags=(
  -target "$target"
  -isysroot "$sdk"
  -fPIC
  -fno-builtin
  -O2
  -I "$builtins"
)

sys_inc="$sdk/usr/include"
header_in_sysroot() {
  local h=$1
  [[ -f "$sys_inc/$h" ]]
}

# Skip TUs that #include a Darwin kernel/libkern header the sysroot lacks.
# Compile failures of other kinds are also excluded (printed).
exclude_reason() {
  local src=$1
  local rel=$2
  # Upstream os_version_check.c is replaced by the in-tree override.
  if [[ "$(basename "$src")" == os_version_check.c ]]; then
    printf 'in-tree override (always-yes _availability_version_check)\n'
    return 0
  fi
  # ELF .init_array CRT glue; Mach-O rejects the section attribute.
  if [[ "$(basename "$src")" == crtbegin.c || "$(basename "$src")" == crtend.c ]]; then
    printf 'ELF CRT glue (crtbegin/crtend), not Darwin builtins\n'
    return 0
  fi
  local inc
  inc=$(grep -E '^[[:space:]]*#include[[:space:]]*[<"]' "$src" 2>/dev/null || true)
  if printf '%s\n' "$inc" | grep -q 'libkern/'; then
    if ! header_in_sysroot libkern/OSCacheControl.h && ! header_in_sysroot libkern/OSAtomic.h; then
      printf 'Darwin kernel header libkern/* absent from sysroot\n'
      return 0
    fi
  fi
  if printf '%s\n' "$inc" | grep -q '<mach/'; then
    if ! header_in_sysroot mach/mach.h && ! header_in_sysroot mach/vm_prot.h; then
      printf 'Darwin kernel header mach/* absent from sysroot\n'
      return 0
    fi
  fi
  if printf '%s\n' "$inc" | grep -q '<Availability.h>'; then
    if ! header_in_sysroot Availability.h; then
      printf 'Darwin header Availability.h absent from sysroot\n'
      return 0
    fi
  fi
  if printf '%s\n' "$inc" | grep -q '<unwind.h>'; then
    if ! header_in_sysroot unwind.h && ! header_in_sysroot mach-o/unwind.h; then
      printf 'unwind.h absent from sysroot\n'
      return 0
    fi
  fi
  return 1
}

# Collect sources: generic C at builtins root + arch-specific .c/.S Apple uses.
declare -a sources=()
while IFS= read -r f; do
  sources+=("$f")
done < <(find "$builtins" -maxdepth 1 -name '*.c' -print | LC_ALL=C sort)

case "$SWIFTCORE_DARWIN_ARCH" in
  x86_64)
    for f in \
      "$builtins/cpu_model/x86.c" \
      "$builtins/i386/fp_mode.c" \
      "$builtins/x86_64/floatdidf.c" \
      "$builtins/x86_64/floatdisf.c" \
      "$builtins/x86_64/floatdixf.c" \
      "$builtins/x86_64/floatundidf.S" \
      "$builtins/x86_64/floatundisf.S" \
      "$builtins/x86_64/floatundixf.S"
    do
      [[ -f "$f" ]] && sources+=("$f")
    done
    ;;
  arm64)
    for f in \
      "$builtins/cpu_model/aarch64.c" \
      "$builtins/aarch64/fp_mode.c"
    do
      [[ -f "$f" ]] && sources+=("$f")
    done
    ;;
  *)
    echo "build_compiler_rt_osx.sh: arch $SWIFTCORE_DARWIN_ARCH not x86_64|arm64" >&2
    exit 1
    ;;
esac

declare -a objs=()
declare -a excluded=()
n_ok=0
for src in "${sources[@]}"; do
  rel=${src#"$builtins"/}
  base=$(basename "$src")
  stem=${base%.*}
  # Disambiguate arch subdir members (fp_mode.c vs i386/fp_mode.c).
  obj_name=$(printf '%s' "$rel" | tr '/.' '__')
  obj="$objdir/${obj_name}.o"
  if reason=$(exclude_reason "$src" "$rel"); then
    excluded+=("$rel ($reason)")
    continue
  fi
  extra=()
  if [[ "$src" == *.S ]]; then
    extra=("${asflags[@]}")
  else
    extra=("${cflags[@]}")
  fi
  err=$tmpdir/$stem.err
  if ! "$cc" "${extra[@]}" -c "$src" -o "$obj" 2>"$err"; then
    why=$(tr '\n' ' ' <"$err" | sed 's/  */ /g; s/^ //; s/ $//' | cut -c1-160)
    excluded+=("$rel (compile failed: ${why:-unknown})")
    continue
  fi
  objs+=("$obj")
  n_ok=$((n_ok + 1))
done

# In-tree os_version_check.c override — always compiled, never skipped.
if ! "$cc" "${cflags[@]}" -c "$override" -o "$objdir/os_version_check.o"; then
  echo "build_compiler_rt_osx.sh: in-tree os_version_check.c failed" >&2
  exit 1
fi
objs+=("$objdir/os_version_check.o")
n_ok=$((n_ok + 1))

if [[ ${#objs[@]} -lt 4 ]]; then
  echo "build_compiler_rt_osx.sh: too few members (${#objs[@]}); refusing empty archive" >&2
  printf '  excluded: %s\n' "${excluded[@]}" >&2
  exit 1
fi

mkdir -p "$(dirname "$out")"
rm -f "$out"
"$ar_bin" rcs "$out" "${objs[@]}"

if [[ ${#excluded[@]} -gt 0 ]]; then
  echo "compiler-rt excluded (${#excluded[@]}):"
  printf '  %s\n' "${excluded[@]}"
else
  echo "compiler-rt excluded: (none)"
fi

sha=$(sha256sum "$out" | awk '{print $1}')
# One-line summary: member count, arch, sha256.
echo "compiler-rt darwin builtins: members=$n_ok arch=$SWIFTCORE_DARWIN_ARCH sha256=$sha $out"

nm_bin=""
for cand in /usr/lib/llvm-18/bin/llvm-nm llvm-nm-18 llvm-nm nm; do
  if command -v "$cand" >/dev/null 2>&1 || [[ -x "$cand" ]]; then
    nm_bin=$cand
    break
  fi
done
if [[ -n "$nm_bin" ]]; then
  "$nm_bin" "$out" 2>/dev/null \
    | grep -E ' (__divti3|__udivti3|__floattidf|__isPlatformVersionAtLeast)$' \
    | sed 's/^/  compiler-rt nm: /' || true
fi
