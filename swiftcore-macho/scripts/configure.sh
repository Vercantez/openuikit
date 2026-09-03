#!/bin/bash
# Configure a stdlib-only, Darwin-target Swift build on a Linux host, against
# the stock swift.org 6.2.4 toolchain and our staged sysroot.
#
# No compiler bootstrap: SWIFT_INCLUDE_TOOLS=OFF makes the build consume the
# installed swiftc/clang instead of building them, so this is minutes of CMake,
# not hours of LLVM.
#
# Arch is a variable, not a rewrite. The recorded Graviton recipe is
#   SWIFTCORE_DARWIN_ARCH=arm64 SWIFT_HOST_VARIANT_ARCH=aarch64
# (those are the defaults on an aarch64 host). On this x86_64 Linux VM the
# defaults become x86_64 / x86_64. Pass SWIFTCORE_DARWIN_ARCH=arm64 to
# configure the original path on any host.
#
#   scripts/configure.sh                 configure + write $W/configure.log
#   scripts/configure.sh --print-flags   print the cmake argv (no configure)
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/probe_lld.inc"

W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
SRC=$W/swift
B=${B:-$W/build}

PRINT_FLAGS=0
CMAKE_EXTRA=()
for a in "$@"; do
  case "$a" in
    --print-flags) PRINT_FLAGS=1 ;;
    *) CMAKE_EXTRA+=("$a") ;;
  esac
done

# Overlay knobs. Recorded arm64 core build left these off except concurrency
# (configure.sh's checked-in defaults). SWIFTCORE_OVERLAYS=1 turns on the
# guest-needed in-tree overlays that do not require an Xcode Darwin SDK:
# _Concurrency (already on), Synchronization, experimental StringProcessing.
# -DSWIFT_BUILD_SDK_OVERLAY=OFF is passed below but Swift 6.2.4 overwrites
# it from SWIFT_BUILD_DYNAMIC_SDK_OVERLAY (default TRUE on a non-Apple host),
# so Platform/swiftDarwin *is* in the ninja graph. ObjectiveC is not a
# CMake target on Linux. build_stdlib.sh derives overlay names from
# `ninja -t targets` and prints CANNOT_STAGE_XCODE_DARWIN_OVERLAYS rather
# than invoking a missing name. See docs/X86_64.md.
#
# Phase-2 guests load _Concurrency + _StringProcessing + Synchronization.
# Overlays therefore also fetch/pass libdispatch (BUILD_LOG §16): CMake with
# STRING_PROCESSING=ON and an empty SWIFT_PATH_TO_STRING_PROCESSING_SOURCE
# dies at stdlib/public/StringProcessing/CMakeLists.txt:41 ("No SOURCES
# given to target") forty lines into the log. Refuse *before* cmake.
OVERLAY_STRING=OFF
OVERLAY_SYNC=OFF
OVERLAY_OBS=OFF
if [ "${SWIFTCORE_OVERLAYS:-0}" = 1 ]; then
  OVERLAY_STRING=ON
  OVERLAY_SYNC=ON
  OVERLAY_OBS=ON
  SWIFTCORE_BUILD_DISPATCH=${SWIFTCORE_BUILD_DISPATCH:-1}
fi

SYNTAX_FLAG=()
if [ -d "$W/swift-syntax" ]; then
  SYNTAX_FLAG=(-DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE="$W/swift-syntax")
fi

STRING_PROCESSING_SRC=${SWIFT_PATH_TO_STRING_PROCESSING_SOURCE:-$W/swift-experimental-string-processing}
LIBDISPATCH_SRC=${SWIFT_PATH_TO_LIBDISPATCH_SOURCE:-$W/libdispatch}

STRING_FLAG=()
DISPATCH_FLAG=()

refuse_checkout() {
  local marker=$1 checkout=$2 pin=$3 expected=$4
  echo "$marker checkout=$checkout pin=$pin tag=$SWIFT_PIN_TAG expected=$expected" >&2
  echo "  bootstrap: SWIFTCORE_OVERLAYS=1 bash $SCRIPT_DIR/bootstrap_box.sh" >&2
  echo "  do not invoke CMake with an empty sibling path" >&2
  exit 2
}

# --print-flags is a dry dump (test_configure_arch.sh). The refuse is for the
# real configure, before cmake, so the operator sees the missing checkout
# instead of CMakeLists.txt:41.
if [ "$PRINT_FLAGS" != 1 ]; then
  if [ "$OVERLAY_STRING" = ON ]; then
    if [ ! -d "$STRING_PROCESSING_SRC/Sources/_StringProcessing" ]; then
      refuse_checkout CANNOT_FETCH_STRING_PROCESSING_SOURCE \
        swift-experimental-string-processing "$STRING_PROCESSING_PIN_COMMIT" \
        "$STRING_PROCESSING_SRC"
    fi
    if [ -d "$STRING_PROCESSING_SRC/.git" ]; then
      got=$(git -C "$STRING_PROCESSING_SRC" rev-parse HEAD)
      if [ "$got" != "$STRING_PROCESSING_PIN_COMMIT" ]; then
        echo "CANNOT_FETCH_STRING_PROCESSING_SOURCE checkout=swift-experimental-string-processing reason=commit-mismatch have=$got want=$STRING_PROCESSING_PIN_COMMIT" >&2
        exit 2
      fi
    fi
  fi
  if [ "${SWIFTCORE_BUILD_DISPATCH:-0}" = 1 ]; then
    if [ ! -d "$LIBDISPATCH_SRC" ] || [ ! -f "$LIBDISPATCH_SRC/CMakeLists.txt" ]; then
      refuse_checkout CANNOT_FETCH_LIBDISPATCH_SOURCE \
        swift-corelibs-libdispatch "$LIBDISPATCH_PIN_COMMIT" \
        "$LIBDISPATCH_SRC"
    fi
    if [ -d "$LIBDISPATCH_SRC/.git" ]; then
      got=$(git -C "$LIBDISPATCH_SRC" rev-parse HEAD)
      if [ "$got" != "$LIBDISPATCH_PIN_COMMIT" ]; then
        echo "CANNOT_FETCH_LIBDISPATCH_SOURCE checkout=swift-corelibs-libdispatch reason=commit-mismatch have=$got want=$LIBDISPATCH_PIN_COMMIT" >&2
        exit 2
      fi
    fi
  fi
fi

# Linux-host ELF / Darwin-target shared links: lld, not gold. Probe before
# cmake so a missing ld.lld is CANNOT_LINKER_LLD rather than ninja's
# "invalid linker name in argument '-fuse-ld=gold'". --print-flags still
# dumps -DSWIFT_USE_LINKER=lld even if this VM has no lld (the dry dump
# must not require the operator box).
if [ "$PRINT_FLAGS" != 1 ]; then
  probe_lld || exit 2
else
  probe_lld || true
fi
LLD_BIN=${LLD_BIN:-/usr/lib/llvm-18/bin}
export LLD_BIN LD_LLD LD64_LLD
# Ubuntu ld64.lld before ${TC}/bin: the swift.org lld refuses platform macOS.
export PATH="${W}/shims:${LLD_BIN}:${TC}/bin:${PATH}"

if [ "$OVERLAY_STRING" = ON ]; then
  STRING_FLAG=(-DSWIFT_PATH_TO_STRING_PROCESSING_SOURCE="$STRING_PROCESSING_SRC")
fi
if [ "${SWIFTCORE_BUILD_DISPATCH:-0}" = 1 ]; then
  # Path satisfies StdlibOptions.cmake:224-226 on a non-Darwin host.
  # ENABLE_DISPATCH stays ON (CMake default TRUE) so the Darwin concurrency
  # overlay still compiles the dispatch executor; patch 8 stops CMake from
  # linking a `dispatch` target that Libdispatch.cmake never creates for OSX.
  DISPATCH_FLAG=(
    -DSWIFT_PATH_TO_LIBDISPATCH_SOURCE="$LIBDISPATCH_SRC"
    -DSWIFT_ENABLE_DISPATCH=ON
  )
fi

# Darwin-target shared links: wrap clang++ so ninja's Linux -shared rule
# becomes -dynamiclib -fuse-ld=lld -nostdlib -lSystem (not gold, not host
# ELF libc++). Compile / host-ELF links pass through.
SHIM_CXX=$W/shims/clang++
mkdir -p "$W/shims"
{
  printf '#!/bin/bash\n'
  printf 'export SWIFTCORE_REAL_CLANGXX=%q\n' "${TC}/bin/clang++"
  printf 'export LLD_BIN=%q\n' "${LLD_BIN}"
  printf 'export TC=%q\n' "${TC}"
  printf 'exec python3 %q "$@"\n' "$SCRIPT_DIR/clangxx_darwin_link.py"
} > "$SHIM_CXX"
chmod +x "$SHIM_CXX"

LINKER_B_FLAGS=()
if [ -n "${LLD_BIN:-}" ]; then
  LINKER_B_FLAGS=(
    -DCMAKE_LINKER="${LD_LLD:-$LLD_BIN/ld.lld}"
    "-DCMAKE_EXE_LINKER_FLAGS=-B${LLD_BIN}"
    "-DCMAKE_SHARED_LINKER_FLAGS=-B${LLD_BIN}"
    "-DCMAKE_MODULE_LINKER_FLAGS=-B${LLD_BIN}"
  )
fi

CMAKE_ARGS=(
  -G Ninja "$SRC"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_C_COMPILER="${TC}/bin/clang"
  -DCMAKE_CXX_COMPILER="${SHIM_CXX}"
  -DSWIFT_USE_LINKER=lld
  "${LINKER_B_FLAGS[@]}"
  -DSWIFT_INCLUDE_TOOLS=OFF
  -DSWIFT_BUILD_STDLIB=ON
  -DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=OFF
  -DSWIFT_BUILD_REMOTE_MIRROR=OFF
  -DSWIFT_BUILD_SDK_OVERLAY=OFF
  -DSWIFT_BUILD_DYNAMIC_STDLIB=ON
  -DSWIFT_BUILD_STATIC_STDLIB=OFF
  -DSWIFT_BUILD_TEST_SUPPORT_MODULES=OFF
  -DSWIFT_INCLUDE_TESTS=OFF
  -DSWIFT_INCLUDE_DOCS=OFF
  -DSWIFT_ENABLE_SWIFT_IN_SWIFT=OFF
  -DBOOTSTRAPPING_MODE=OFF
  -DSWIFT_NATIVE_SWIFT_TOOLS_PATH="${TC}/bin"
  -DSWIFT_NATIVE_CLANG_TOOLS_PATH="${TC}/bin"
  "${SYNTAX_FLAG[@]}"
  -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm
  -DClang_DIR=/usr/lib/llvm-18/lib/cmake/clang
  -DLLVM_BUILD_LIBRARY_DIR=/usr/lib/llvm-18/lib
  -DLLVM_LIBRARY_DIRS=/usr/lib/llvm-18/lib
  -DLLVM_TOOLS_BINARY_DIR=/usr/lib/llvm-18/bin
  -DLLVM_MAIN_INCLUDE_DIR=/usr/lib/llvm-18/include
  -DSWIFT_HOST_VARIANT_SDK=LINUX
  -DSWIFT_HOST_VARIANT_ARCH="${SWIFT_HOST_VARIANT_ARCH}"
  -DSWIFT_SDKS=OSX
  -DSWIFT_SDK_OSX_PATH="$SDK"
  -DSWIFT_SDK_OSX_ARCHITECTURES="${SWIFTCORE_DARWIN_ARCH}"
  -DSWIFT_SDK_OSX_MODULE_ARCHITECTURES="${SWIFTCORE_DARWIN_ARCH}"
  -DSWIFT_DARWIN_SUPPORTED_ARCHS="${SWIFTCORE_DARWIN_ARCH}"
  -DSWIFT_DARWIN_MODULE_ARCHS="${SWIFTCORE_DARWIN_ARCH}"
  -DSWIFT_DARWIN_DEPLOYMENT_VERSION_OSX=13.0
  -DSWIFT_PRIMARY_VARIANT_SDK=OSX
  -DSWIFT_PRIMARY_VARIANT_ARCH="${SWIFTCORE_DARWIN_ARCH}"
  -DSWIFT_HOST_TRIPLE="${SWIFT_HOST_TRIPLE}"
  -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=ON
  -DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=OFF
  -DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=OFF
  -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING="${OVERLAY_STRING}"
  -DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION="${OVERLAY_OBS}"
  -DSWIFT_ENABLE_SYNCHRONIZATION="${OVERLAY_SYNC}"
  -DSWIFT_ENABLE_VOLATILE=OFF
  -DSWIFT_ENABLE_BACKTRACING=OFF
  -DSWIFT_STDLIB_ENABLE_OBJC_INTEROP=ON
  -DSWIFT_INCLUDE_APINOTES=ON
  "${STRING_FLAG[@]}"
  "${DISPATCH_FLAG[@]}"
  "${CMAKE_EXTRA[@]}"
)

if [ "$PRINT_FLAGS" = 1 ]; then
  printf 'SWIFTCORE_DARWIN_ARCH=%s\n' "$SWIFTCORE_DARWIN_ARCH"
  printf 'SWIFT_HOST_VARIANT_ARCH=%s\n' "$SWIFT_HOST_VARIANT_ARCH"
  printf 'SWIFT_HOST_TRIPLE=%s\n' "$SWIFT_HOST_TRIPLE"
  printf 'SWIFTCORE_MODULE_TRIPLE=%s\n' "$SWIFTCORE_MODULE_TRIPLE"
  printf 'SWIFTCORE_NINJA_CORE=%s\n' "$SWIFTCORE_NINJA_CORE"
  printf 'TC=%s\n' "$TC"
  printf 'SDK=%s\n' "$SDK"
  printf 'SRC=%s\n' "$SRC"
  printf 'B=%s\n' "$B"
  printf 'SWIFTCORE_OVERLAYS=%s\n' "${SWIFTCORE_OVERLAYS:-0}"
  printf 'SWIFTCORE_BUILD_DISPATCH=%s\n' "${SWIFTCORE_BUILD_DISPATCH:-0}"
  printf 'STRING_PROCESSING_SRC=%s\n' "$STRING_PROCESSING_SRC"
  printf 'LIBDISPATCH_SRC=%s\n' "$LIBDISPATCH_SRC"
  printf 'SWIFT_USE_LINKER=lld\n'
  printf 'LLD_BIN=%s\n' "${LLD_BIN:-}"
  printf 'LD_LLD=%s\n' "${LD_LLD:-}"
  printf 'LD64_LLD=%s\n' "${LD64_LLD:-}"
  printf 'CMAKE_CXX_COMPILER=%s\n' "${SHIM_CXX}"
  printf 'SWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=%s\n' "${OVERLAY_OBS}"
  printf 'cmake'
  for a in "${CMAKE_ARGS[@]}"; do
    printf ' %q' "$a"
  done
  printf '\n'
  exit 0
fi

rm -rf "$B"; mkdir -p "$B" "$W/shims"
cd "$B"

cmake "${CMAKE_ARGS[@]}" 2>&1 | tee "$W/configure.log"

echo "configure exit: ${PIPESTATUS[0]}"
echo "darwin_arch=${SWIFTCORE_DARWIN_ARCH} host_arch=${SWIFT_HOST_VARIANT_ARCH} ninja_core=${SWIFTCORE_NINJA_CORE}"
