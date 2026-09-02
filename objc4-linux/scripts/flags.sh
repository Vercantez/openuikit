# Shared compile flags for objc4-linux. Sourced inside the container by
# scripts/inventory.sh; mirrored in CMakeLists.txt (keep the two in sync).
#
# The load-bearing one is -D__arm64__=1: __arm64__ is an Apple-only predefine
# and objc4 has 43 `#if __arm64__` sites, including the cache_t layout that C
# and the assembly messenger must agree on. See docs/PORT_MAP.md 2.7.

WORK=${WORK:-/work}
SRC=$WORK/build/objc4-src
GEN=$WORK/build/gen

OBJC4_ARCH_FLAGS=""
case "${OBJC4_LINUX_ARCH:-aarch64}" in
  aarch64) OBJC4_ARCH_FLAGS="-D__arm64__=1 -D__arm64=1" ;;
  x86_64)  OBJC4_ARCH_FLAGS="" ;;
esac

OBJC4_INCLUDES="-I$GEN/include -I$SRC/runtime -I$WORK/compat"

OBJC4_DEFINES="\
 -D_GNU_SOURCE \
 -DOBJC4LINUX=1 \
 -DNDEBUG \
 -D__OBJC2__=1 \
 -DOBJC_DECLARE_SYMBOLS=1 \
 $OBJC4_ARCH_FLAGS"

OBJC4_WARN="-Wno-unused-parameter -Wno-unknown-pragmas -Wno-deprecated-declarations \
 -Wno-gcc-compat -Wno-unused-function -Wno-cast-function-type-mismatch \
 -Wno-unknown-warning-option"

OBJC4_COMMON="-fPIC -fno-strict-aliasing -fblocks -fno-exceptions -fno-rtti \
 -fvisibility=hidden -funwind-tables \
 -include objc4linux/darwin-cdefs.h"

OBJC4_CXXFLAGS="-std=gnu++20 $OBJC4_COMMON $OBJC4_DEFINES $OBJC4_INCLUDES $OBJC4_WARN"
OBJC4_CFLAGS="-std=gnu11 $OBJC4_COMMON $OBJC4_DEFINES $OBJC4_INCLUDES $OBJC4_WARN"
OBJC4_OBJCXXFLAGS="-x objective-c++ -fobjc-runtime=macosx-10.15 $OBJC4_CXXFLAGS"
# objc-magicsel.m is deliberately plain ObjC, not ObjC++: it contains
# `@selector(<emoji>)`, which C++ rejects as an identifier (Apple's own
# comment cites rdar://84895077). Compiling it as ObjC++ reintroduces the bug.
OBJC4_OBJCFLAGS="-x objective-c -fobjc-runtime=macosx-10.15 $OBJC4_CFLAGS"

OBJC4_ASFLAGS="-x assembler-with-cpp $OBJC4_DEFINES $OBJC4_INCLUDES -fPIC"
