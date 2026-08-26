#!/bin/bash
# Configure a stdlib-only, Darwin-target (arm64-apple-macos) Swift build on a
# Linux host, against the stock swift.org 6.2.4 toolchain and our staged sysroot.
#
# No compiler bootstrap: SWIFT_INCLUDE_TOOLS=OFF makes the build consume the
# installed swiftc/clang instead of building them, so this is minutes of CMake,
# not hours of LLVM.
set -euo pipefail
W=${W:-$HOME/work}
TC=${TC:-/opt/swift624/usr}
SDK=$W/sdk/MacOSX.sdk
SRC=$W/swift
B=${B:-$W/build}

export PATH="$W/shims:$TC/bin:/usr/lib/llvm-18/bin:$PATH"

rm -rf "$B"; mkdir -p "$B"
cd "$B"

cmake -G Ninja "$SRC" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="$TC/bin/clang" \
  -DCMAKE_CXX_COMPILER="$TC/bin/clang++" \
  \
  `# ---- stdlib only: no compiler, no LLVM build, no cmark, no tablegen ----` \
  -DSWIFT_INCLUDE_TOOLS=OFF \
  -DSWIFT_BUILD_STDLIB=ON \
  -DSWIFT_BUILD_STDLIB_EXTRA_TOOLCHAIN_CONTENT=OFF \
  -DSWIFT_BUILD_REMOTE_MIRROR=OFF \
  -DSWIFT_BUILD_SDK_OVERLAY=OFF \
  -DSWIFT_BUILD_DYNAMIC_STDLIB=ON \
  -DSWIFT_BUILD_STATIC_STDLIB=OFF \
  -DSWIFT_BUILD_TEST_SUPPORT_MODULES=OFF \
  -DSWIFT_INCLUDE_TESTS=OFF \
  -DSWIFT_INCLUDE_DOCS=OFF \
  -DSWIFT_ENABLE_SWIFT_IN_SWIFT=OFF \
  -DBOOTSTRAPPING_MODE=OFF \
  \
  `# ---- consume the stock 6.2.4 toolchain as the "native" tools ----` \
  -DSWIFT_NATIVE_SWIFT_TOOLS_PATH="$TC/bin" \
  -DSWIFT_NATIVE_CLANG_TOOLS_PATH="$TC/bin" \
  -DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE="$W/swift-syntax" \
  \
  `# ---- Ubuntu's installed LLVM 18 (an installed LLVMConfig omits some vars` \
  `#      a build-tree one sets; supply them explicitly) ----` \
  -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm \
  -DClang_DIR=/usr/lib/llvm-18/lib/cmake/clang \
  -DLLVM_BUILD_LIBRARY_DIR=/usr/lib/llvm-18/lib \
  -DLLVM_LIBRARY_DIRS=/usr/lib/llvm-18/lib \
  -DLLVM_TOOLS_BINARY_DIR=/usr/lib/llvm-18/bin \
  -DLLVM_MAIN_INCLUDE_DIR=/usr/lib/llvm-18/include \
  \
  `# ---- host is Linux, target is Darwin ----` \
  -DSWIFT_HOST_VARIANT_SDK=LINUX \
  -DSWIFT_HOST_VARIANT_ARCH=aarch64 \
  -DSWIFT_SDKS="OSX" \
  -DSWIFT_SDK_OSX_PATH="$SDK" \
  -DSWIFT_SDK_OSX_ARCHITECTURES=arm64 \
  -DSWIFT_SDK_OSX_MODULE_ARCHITECTURES=arm64 \
  -DSWIFT_DARWIN_SUPPORTED_ARCHS=arm64 \
  -DSWIFT_DARWIN_MODULE_ARCHS=arm64 \
  -DSWIFT_DARWIN_DEPLOYMENT_VERSION_OSX=13.0 \
  -DSWIFT_PRIMARY_VARIANT_SDK=OSX \
  -DSWIFT_PRIMARY_VARIANT_ARCH=arm64 \
  -DSWIFT_HOST_TRIPLE=aarch64-unknown-linux-gnu \
  \
  `# ---- concurrency et al are separate libs; core first ----` \
  -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=OFF \
  -DSWIFT_ENABLE_SYNCHRONIZATION=OFF \
  -DSWIFT_ENABLE_VOLATILE=OFF \
  -DSWIFT_ENABLE_BACKTRACING=OFF \
  -DSWIFT_STDLIB_ENABLE_OBJC_INTEROP=ON \
  "$@" 2>&1 | tee "$W/configure.log"

echo "configure exit: ${PIPESTATUS[0]}"
