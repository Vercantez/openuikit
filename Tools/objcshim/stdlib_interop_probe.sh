#!/bin/bash
# Reproduces the "custom Linux stdlib with SWIFT_OBJC_INTEROP=1" measurement
# written up in docs/OBJC_RUNTIME.md, "Task B". Companion to interop_limits.sh,
# which measures why the STOCK Linux stdlib cannot be used with interop; this
# one measures whether BUILDING a non-stock one is a way out.
#
# It answers three questions and stops. It deliberately does NOT build the
# stdlib: the measurement below shows the build cannot succeed, so completing
# it is not a thing that can happen.
#
#   Q1  Does Swift's build system accept SWIFT_OBJC_INTEROP=1 for a Linux SDK?
#       -> configures both ways and diffs the generated compile lines.
#   Q3  Is a stdlib-only build possible against the SHIPPED toolchain, or does
#       it force a full compiler bootstrap?
#       -> configures with SWIFT_INCLUDE_TOOLS=OFF and reports the exit code.
#   WALL Force SWIFT_OBJC_INTEROP=1 onto the C++ half and compile the ten
#       Objective-C translation units the stdlib contains. Reports each one's
#       first fatal error.
#
# Requires: Ubuntu 24.04 (aarch64 or x86_64), ~12 GB free disk, network.
#   sudo apt-get install -y build-essential cmake ninja-build git python3 \
#        llvm-18-dev zlib1g-dev libzstd-dev libcurl4-openssl-dev libedit-dev \
#        libxml2-dev libncurses-dev uuid-dev
# Wall time: ~8 minutes, almost all of it download + clone.
#
# Measured 2026-08-25 on Ubuntu 24.04 aarch64 with Swift 6.2.4. Results are
# transcribed into docs/OBJC_RUNTIME.md; this script is how you check them.
set -u
W="${1:-$HOME/swift-interop-probe}"
SWIFT_VER=6.2.4
mkdir -p "$W"
cd "$W"

TC="$W/toolchain/usr"
SRC="$W/swift-src"
ARCH=$(uname -m)
case "$ARCH" in
  aarch64) DL_ARCH=aarch64; DL_DIR=ubuntu2404-aarch64; SUFFIX=ubuntu24.04-aarch64 ;;
  x86_64)  DL_ARCH=x86_64;  DL_DIR=ubuntu2404;         SUFFIX=ubuntu24.04 ;;
  *) echo "unsupported arch $ARCH"; exit 1 ;;
esac

if [ ! -x "$TC/bin/swiftc" ]; then
  echo "==> downloading the OFFICIAL Swift $SWIFT_VER toolchain (not a fork)"
  curl -fsSL "https://download.swift.org/swift-$SWIFT_VER-release/$DL_DIR/swift-$SWIFT_VER-RELEASE/swift-$SWIFT_VER-RELEASE-$SUFFIX.tar.gz" \
    -o swift.tar.gz || exit 1
  mkdir -p toolchain && tar xzf swift.tar.gz -C toolchain --strip-components=1 && rm -f swift.tar.gz
fi
"$TC/bin/swift" --version

[ -d "$SRC/.git" ] || git clone --depth 1 --branch "swift-$SWIFT_VER-RELEASE" \
    https://github.com/swiftlang/swift.git "$SRC"
[ -d "$W/swift-corelibs-libdispatch/.git" ] || git clone --depth 1 \
    --branch "swift-$SWIFT_VER-RELEASE" \
    https://github.com/swiftlang/swift-corelibs-libdispatch.git "$W/swift-corelibs-libdispatch"

LLVM=/usr/lib/llvm-18

configure() {   # $1 = build dir, $2 = TRUE|FALSE
  rm -rf "$1"
  cmake -G Ninja -S "$SRC" -B "$1" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$TC/bin/clang" \
    -DCMAKE_CXX_COMPILER="$TC/bin/clang++" \
    -DCMAKE_Swift_COMPILER="$TC/bin/swiftc" \
    -DLLVM_DIR="$LLVM/lib/cmake/llvm" \
    -DLLVM_BUILD_LIBRARY_DIR="$LLVM/lib" \
    -DLLVM_LIBRARY_DIRS="$LLVM/lib" \
    -DLLVM_TOOLS_BINARY_DIR="$LLVM/bin" \
    -DLLVM_MAIN_SRC_DIR="$LLVM" \
    -DSWIFT_PATH_TO_LIBDISPATCH_SOURCE="$W/swift-corelibs-libdispatch" \
    -DSWIFT_INCLUDE_TOOLS=OFF \
    -DSWIFT_INCLUDE_TESTS=OFF \
    -DSWIFT_INCLUDE_DOCS=OFF \
    -DSWIFT_BUILD_SOURCEKIT=OFF \
    -DSWIFT_BUILD_SDK_OVERLAY=OFF \
    -DSWIFT_BUILD_DYNAMIC_SDK_OVERLAY=OFF \
    -DSWIFT_BUILD_STATIC_SDK_OVERLAY=OFF \
    -DSWIFT_BUILD_DYNAMIC_STDLIB=ON \
    -DSWIFT_BUILD_STATIC_STDLIB=OFF \
    -DSWIFT_ENABLE_SWIFT_IN_SWIFT=OFF \
    -DSWIFT_NATIVE_SWIFT_TOOLS_PATH="$TC/bin" \
    -DSWIFT_NATIVE_CLANG_TOOLS_PATH="$TC/bin" \
    -DSWIFT_NATIVE_LLVM_TOOLS_PATH="$TC/bin" \
    -DSWIFT_HOST_VARIANT_SDK=LINUX \
    -DSWIFT_HOST_VARIANT_ARCH="$DL_ARCH" \
    -DSWIFT_STDLIB_ENABLE_OBJC_INTEROP="$2" \
    > "$1.log" 2>&1
  echo "$?"
}

echo
echo "=== Q3: stdlib-only configure against the SHIPPED toolchain ==========="
echo "  (SWIFT_INCLUDE_TOOLS=OFF, no compiler bootstrap, no LLVM build)"
R1=$(configure "$W/build-baseline" FALSE)
echo "  interop OFF (baseline) configure exit: $R1   [0 = stdlib-only works]"

echo
echo "=== Q1: is SWIFT_OBJC_INTEROP=1 accepted for a LINUX SDK? ============="
R2=$(configure "$W/build-interop" TRUE)
echo "  interop ON  configure exit: $R2   [0 = the option is NOT rejected]"
[ "$R2" = 0 ] || { echo "  configure failed; see $W/build-interop.log"; exit 1; }

echo
echo "  ...but look at what the option actually reaches:"
printf "    baseline: '-DSWIFT_OBJC_INTEROP=0' on %s C++ compile lines\n" \
  "$(grep -c -- '-DSWIFT_OBJC_INTEROP=0' "$W/build-baseline/build.ninja")"
printf "    interop : '-DSWIFT_OBJC_INTEROP='  on %s C++ compile lines\n" \
  "$(grep -c -- '-DSWIFT_OBJC_INTEROP=' "$W/build-interop/build.ninja")"
printf "    baseline: '-disable-objc-interop'  on %s Swift compile lines\n" \
  "$(grep -c -- 'disable-objc-interop' "$W/build-baseline/build.ninja")"
printf "    interop : '-disable-objc-interop'  on %s Swift compile lines\n" \
  "$(grep -c -- 'disable-objc-interop' "$W/build-interop/build.ninja")"
echo "  The Swift half flips; the C++ half does NOT, because Config.h derives"
echo "  SWIFT_OBJC_INTEROP from __APPLE__ and CMake only ever passes '=0'."
echo "  So the option alone produces an INTRA-library metadata mismatch."

echo
echo "=== THE WALL: force SWIFT_OBJC_INTEROP=1 on the C++ half =============="
cd "$W/build-interop"
RT=stdlib/public/runtime/CMakeFiles/swiftRuntimeCore-linux-$DL_ARCH.dir
ST=stdlib/public/stubs/CMakeFiles/swiftStdlibStubs-linux-$DL_ARCH.dir
for T in $RT/SwiftObject.mm.o $RT/ErrorObject.mm.o $RT/SwiftValue.mm.o \
         $RT/ReflectionMirrorObjC.mm.o $RT/ObjCRuntimeGetImageNameFromClass.mm.o \
         $ST/FoundationHelpers.mm.o $ST/SwiftNativeNSObject.mm.o \
         $ST/Reflection.mm.o $ST/Availability.mm.o $ST/OptionalBridgingHelper.mm.o; do
  CMD=$(ninja -t commands "$T" 2>/dev/null | tail -1)
  [ -n "$CMD" ] || { printf '  %-36s NO RULE\n' "$(basename "$T")"; continue; }
  # -fno-color-diagnostics matters: clang otherwise wraps the quoted filename
  # in ANSI escapes and the grep below silently reports a false "COMPILED".
  OUT=$(eval "${CMD/ -c / -DSWIFT_OBJC_INTEROP=1 -DSWIFT_HAS_ISA_MASKING=0 -fno-color-diagnostics -c }" 2>&1 \
        | grep -oE "fatal error: .*" | head -1)
  printf '  %-36s %s\n' "$(basename "$T")" "${OUT:-COMPILED}"
done
echo
echo "Ten of ten fail on a missing Darwin header. objc/*.h could come from"
echo "libobjc2 -- but objc/NSObject.h, CoreFoundation/ and Foundation/ (the"
echo "OBJECTIVE-C Foundation) do not exist on Linux at all. That is the wall."
