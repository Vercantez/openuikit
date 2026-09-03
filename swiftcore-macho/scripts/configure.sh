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

W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
SRC=$W/swift
B=${B:-$W/build}

export PATH="${W}/shims:${TC}/bin:/usr/lib/llvm-18/bin:${PATH}"

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
# Darwin/ObjectiveC SDK overlays stay OFF: SWIFT_BUILD_SDK_OVERLAY needs
# Xcode module maps this Linux sysroot does not have. See docs/X86_64.md.
OVERLAY_STRING=OFF
OVERLAY_SYNC=OFF
if [ "${SWIFTCORE_OVERLAYS:-0}" = 1 ]; then
  OVERLAY_STRING=ON
  OVERLAY_SYNC=ON
fi

SYNTAX_FLAG=()
if [ -d "$W/swift-syntax" ]; then
  SYNTAX_FLAG=(-DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE="$W/swift-syntax")
fi

DISPATCH_FLAG=()
if [ "${SWIFTCORE_BUILD_DISPATCH:-0}" = 1 ] && [ -d "${SWIFT_PATH_TO_LIBDISPATCH_SOURCE:-$W/libdispatch}" ]; then
  DISPATCH_FLAG=(-DSWIFT_PATH_TO_LIBDISPATCH_SOURCE="${SWIFT_PATH_TO_LIBDISPATCH_SOURCE:-$W/libdispatch}")
fi

CMAKE_ARGS=(
  -G Ninja "$SRC"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_C_COMPILER="${TC}/bin/clang"
  -DCMAKE_CXX_COMPILER="${TC}/bin/clang++"
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
  -DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=OFF
  -DSWIFT_ENABLE_SYNCHRONIZATION="${OVERLAY_SYNC}"
  -DSWIFT_ENABLE_VOLATILE=OFF
  -DSWIFT_ENABLE_BACKTRACING=OFF
  -DSWIFT_STDLIB_ENABLE_OBJC_INTEROP=ON
  -DSWIFT_INCLUDE_APINOTES=ON
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
